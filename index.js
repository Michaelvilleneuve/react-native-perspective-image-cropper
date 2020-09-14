/* eslint-disable no-underscore-dangle */
import React, { Component } from 'react'
import {
  NativeModules,
  PanResponder,
  Dimensions,
  Image,
  View,
  Animated,
  ActivityIndicator,
} from 'react-native'
import Svg, { Polygon } from 'react-native-svg'

const AnimatedPolygon = Animated.createAnimatedComponent(Polygon)

const TOP = 0
const RIGHT = 1
const BOTTOM = 2
const LEFT = 3

const HORIZONTAL_PADDING = 15

class CustomCrop extends Component {
  state = {}
  constructor(props) {
    super(props)

    const corners = []
    for (let i = 0; i < 4; i++) {
      corners[i] = { position: new Animated.ValueXY(), delta: { x: 0, y: 0 } }
      corners[i].panResponder = this.cornerPanResponser(corners[i])
    }

    const midPoints = []
    for (let i = 0; i < 4; i++) {
      midPoints[i] = {
        position: new Animated.ValueXY(),
        delta: { x: 0, y: 0 },
      }
      midPoints[i].panResponder = this.midPointPanResponser(midPoints[i], i)
    }

    this.state = {
      imageWidth: props.width,
      imageHeight: props.height,
      image: props.initialImage,
      corners,
      midPoints,
      isLoading: true,
      zoom: 1,
      viewWidth: props.width,
      viewHeight: props.height,
      imageLayoutWidth: props.width,
      imageLayoutHeight: props.height,
    }
  }
  onLayout = (event) => {
    const { layout } = event.nativeEvent
    const { imageHeight, corners, viewWidth, viewHeight } = this.state

    if (layout.width === viewWidth && layout.height === viewHeight) {
      return
    }

    const { defaultFrameCoordinates } = this.props
    const zoom = layout.height / imageHeight

    corners[0].position.setValue({
      x: defaultFrameCoordinates.left,
      y: defaultFrameCoordinates.top,
    })
    corners[1].position.setValue({
      x: layout.width - defaultFrameCoordinates.right,
      y: defaultFrameCoordinates.top,
    })
    corners[2].position.setValue({
      x: HORIZONTAL_PADDING,
      y: defaultFrameCoordinates.bottom,
    })
    corners[3].position.setValue({
      x: layout.width - defaultFrameCoordinates.right,
      y: defaultFrameCoordinates.bottom,
    })

    this.updateMidPoints()

    this.findDocument()

    this.setState({
      isLoading: false,
      viewWidth: layout.width,
      viewHeight: layout.height,
      imageLayoutWidth: layout.width,
      imageLayoutHeight: layout.height,
      offsetVerticle: 0,
      offsetHorizontal: 0,
      zoom,
      overlayPositions: this.getOverlayString(),
    })
  }
  cornerPanResponser = (corner) => {
    return PanResponder.create({
      onStartShouldSetPanResponder: () => true,
      onPanResponderMove: (e, gesture) => {
        this.moveCorner(corner, gesture.dx, gesture.dy)
        this.setState({ overlayPositions: this.getOverlayString() })
      },
      onPanResponderRelease: () => {
        corner.delta = { x: 0, y: 0 }
      },
      onPanResponderGrant: () => {
        corner.delta = { x: 0, y: 0 }
      },
    })
  }
  moveCorner = (corner, dx, dy) => {
    const { delta, position, imageLayoutWidth, imageLayoutHeight } = corner
    position.setValue({
      x: Math.min(Math.max(position.x._value + dx - delta.x, 0), imageLayoutWidth),
      y: Math.min(Math.max(position.y._value + dy - delta.y, 0), imageLayoutHeight),
    })
    corner.delta = { x: dx, y: dy }
    this.updateMidPoints()
  }
  midPointPanResponser = (midPoint, side) => {
    const { corners } = this.state
    return PanResponder.create({
      onStartShouldSetPanResponder: () => true,
      onPanResponderMove: (e, gesture) => {
        const { topLeft, topRight, bottomLeft, bottomRight } = this.getCorners()
        switch (side) {
          case TOP:
            this.moveCorner(topLeft, 0, gesture.dy)
            this.moveCorner(topRight, 0, gesture.dy)
            break
          case RIGHT:
            this.moveCorner(bottomRight, gesture.dx, 0)
            this.moveCorner(topRight, gesture.dx, 0)
            break
          case BOTTOM:
            this.moveCorner(bottomLeft, 0, gesture.dy)
            this.moveCorner(bottomRight, 0, gesture.dy)
            break
          case LEFT:
            this.moveCorner(bottomLeft, gesture.dx, 0)
            this.moveCorner(topLeft, gesture.dx, 0)
            break
          default:
            break
        }
        this.setState({ overlayPositions: this.getOverlayString() })
      },
      onPanResponderRelease: () => {
        corners.forEach((corner) => (corner.delta = { x: 0, y: 0 }))
      },
      onPanResponderGrant: () => {},
    })
  }
  crop = () => {
    const { isLoading, image, imageHeight, imageWidth } = this.state
    if (!isLoading) {
      const { topLeft, topRight, bottomLeft, bottomRight } = this.getCorners()
      const coordinates = {
        topLeft: this.viewCoordinatesToImageCoordinates(topLeft),
        topRight: this.viewCoordinatesToImageCoordinates(topRight),
        bottomLeft: this.viewCoordinatesToImageCoordinates(bottomLeft),
        bottomRight: this.viewCoordinatesToImageCoordinates(bottomRight),
        height: imageHeight,
        width: imageWidth,
      }

      NativeModules.CustomCropManager.crop(coordinates, image, (err, res) => {
        this.props.updateImage(res.image, coordinates)
      })
    }
  }
  findDocument = () => {
    const { corners, zoom, imageWidth, viewWidth, image } = this.state
    NativeModules.CustomCropManager.findDocument(image, (err, res) => {
      if (res) {
        const offsetHorizontal = Math.round((imageWidth * zoom - viewWidth) / 2)
        corners[0].position.setValue({
          x: res.topLeft.x * zoom - offsetHorizontal,
          y: res.topLeft.y * zoom,
        })
        corners[1].position.setValue({
          x: res.topRight.x * zoom - offsetHorizontal,
          y: res.topRight.y * zoom,
        })
        corners[2].position.setValue({
          x: res.bottomLeft.x * zoom - offsetHorizontal,
          y: res.bottomLeft.y * zoom,
        })
        corners[3].position.setValue({
          x: res.bottomRight.x * zoom - offsetHorizontal,
          y: res.bottomRight.y * zoom,
        })
        this.updateMidPoints()
      }
      this.setState({
        isLoading: false,
        overlayPositions: this.getOverlayString(),
      })
    })
  }
  getCorners = () => {
    const { corners } = this.state

    const topSorted = [...corners].sort((a, b) => a.position.y._value > b.position.y._value)
    const topLeft =
      topSorted[0].position.x._value < topSorted[1].position.x._value ? topSorted[0] : topSorted[1]
    const topRight =
      topSorted[0].position.x._value >= topSorted[1].position.x._value ? topSorted[0] : topSorted[1]
    const bottomLeft =
      topSorted[2].position.x._value < topSorted[3].position.x._value ? topSorted[2] : topSorted[3]
    const bottomRight =
      topSorted[2].position.x._value >= topSorted[3].position.x._value ? topSorted[2] : topSorted[3]

    return { topLeft, topRight, bottomLeft, bottomRight }
  }
  setMidPoint = (point, start, end) => {
    point.position.setValue({
      x: (start.position.x._value + end.position.x._value) / 2,
      y: (start.position.y._value + end.position.y._value) / 2,
    })
  }
  updateMidPoints = () => {
    const { topLeft, topRight, bottomLeft, bottomRight } = this.getCorners()
    const { midPoints } = this.state
    this.setMidPoint(midPoints[TOP], topLeft, topRight)
    this.setMidPoint(midPoints[RIGHT], bottomRight, topRight)
    this.setMidPoint(midPoints[BOTTOM], bottomRight, bottomLeft)
    this.setMidPoint(midPoints[LEFT], topLeft, bottomLeft)
  }
  getOverlayString = () => {
    const { topLeft, topRight, bottomLeft, bottomRight } = this.getCorners()
    return `${topLeft.position.x._value},${topLeft.position.y._value} ${topRight.position.x._value},${topRight.position.y._value} ${bottomRight.position.x._value},${bottomRight.position.y._value} ${bottomLeft.position.x._value},${bottomLeft.position.y._value}`
  }
  offset = (position) => ({
    x: position.x._value + position.x._offset,
    y: position.y._value + position.y._offset,
  })
  viewCoordinatesToImageCoordinates = (corner) => {
    const { zoom } = this.state
    return {
      x: corner.position.x._value * (1 / zoom),
      y: corner.position.y._value * (1 / zoom),
    }
  }
  render() {
    const {
      offsetVerticle,
      offsetHorizontal,
      corners,
      midPoints,
      overlayPositions,
      isLoading,
      image,
      viewHeight,
    } = this.state
    const { overlayColor, overlayStrokeWidth, overlayOpacity, overlayStrokeColor } = this.props
    return (
      <View style={{ flex: 1, width: '100%' }} onLayout={this.onLayout}>
        <Image style={{ flex: 1, width: '100%' }} resizeMode="cover" source={{ uri: image }} />
        {isLoading && (
          <View
            style={{
              position: 'absolute',
              justifyContent: 'center',
              alignItems: 'center',
              width: '100%',
              height: '100%',
            }}
          >
            <ActivityIndicator color={overlayColor} size="large" />
          </View>
        )}
        {!isLoading && (
          <View
            style={{
              position: 'absolute',
              top: offsetVerticle,
              bottom: offsetVerticle,
              left: offsetHorizontal,
              right: offsetHorizontal,
            }}
          >
            <Svg
              height={viewHeight}
              width={Dimensions.get('window').width}
              style={{ position: 'absolute', left: 0, top: 0 }}
            >
              <AnimatedPolygon
                ref={(ref) => {
                  this.polygon = ref
                }}
                fill={overlayColor || 'blue'}
                fillOpacity={overlayOpacity || 0.5}
                stroke={overlayStrokeColor || 'blue'}
                points={overlayPositions}
                strokeWidth={overlayStrokeWidth || 3}
              />
            </Svg>

            {midPoints.map((point, index) => (
              <Animated.View
                key={`point-${index}`}
                {...point.panResponder.panHandlers}
                style={[point.position.getLayout(), s(this.props).handler]}
              >
                <View
                  style={[
                    index === TOP || index === BOTTOM
                      ? s(this.props).handleMidHorizontal
                      : s(this.props).handleMidVertical,
                  ]}
                />
              </Animated.View>
            ))}

            {corners.map((corner, index) => (
              <Animated.View
                key={`corner-${index}`}
                {...corner.panResponder.panHandlers}
                style={[corner.position.getLayout(), s(this.props).handler]}
              >
                <View style={[s(this.props).handlerRound]} />
              </Animated.View>
            ))}
          </View>
        )}
      </View>
    )
  }
}

const s = (props) => ({
  handlerRound: {
    width: 20,
    position: 'absolute',
    height: 20,
    borderRadius: 10,
    backgroundColor: props.handlerBackroundColor || 'blue',
    borderColor: props.borderColor || 'blue',
    borderWidth: 2,
  },
  handleMidHorizontal: {
    width: 40,
    position: 'absolute',
    height: 15,
    borderRadius: 10,
    backgroundColor: props.handlerBackroundColor || 'blue',
    borderColor: props.borderColor || 'blue',
    borderWidth: 2,
  },
  handleMidVertical: {
    width: 15,
    position: 'absolute',
    height: 40,
    borderRadius: 10,
    backgroundColor: props.handlerBackroundColor || 'blue',
    borderColor: props.borderColor || 'blue',
    borderWidth: 2,
  },
  handler: {
    height: 60,
    width: 60,
    marginLeft: -30,
    marginTop: -30,
    alignItems: 'center',
    justifyContent: 'center',
    position: 'absolute',
    backgroundColor: 'transparent',
    borderRadius: 50,
  },
})

export default CustomCrop
