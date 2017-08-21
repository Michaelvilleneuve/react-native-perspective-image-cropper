
# React Native perspective image cropper 📐🖼

A component that allows you to perform custom image crop and perspective correction !

![Demo image](https://s3-eu-west-1.amazonaws.com/michaelvilleneuve/demo-crop.gif)

##### Designed to work with React Native Document Scanner
https://github.com/Michaelvilleneuve/react-native-document-scanner

![Demo gif](https://raw.githubusercontent.com/Michaelvilleneuve/react-native-document-scanner/master/images/demo.gif)

## Installation 🚀🚀

`$ npm install react-native-perspective-image-cropper --save`

`$ react-native link react-native-perspective-image-cropper`

This library uses react-native-svg, you must link its content too.

`$ react-native link react-native-perspective-image-cropper/node_modules/react-native-svg`

Download opencv2.framework from here https://sourceforge.net/projects/opencvlibrary/files/opencv-ios/2.4.13/ and unzip it in your `ios` then in XCode, right click on project, choose `add files to yourproject` and select `opencv2.framework`

![instructions](https://s3-eu-west-1.amazonaws.com/michaelvilleneuve/Capture+d%E2%80%99e%CC%81cran+2017-08-21+a%CC%80+10.13.35.png)

## Crop image

- First get component ref
```javascript
<CustomCrop ref={(ref) => this.customCrop = ref} />
```

- Then call :
```javascript
this.customCrop.crop();
```

## Props

| Props             | Type            | Required | Description                                                                                |
|-------------------|-----------------|-----------------|---------------------------------------------------------------------------------------------|
| `updateImage` | `Func`        | Yes | Returns the cropped image and the coordinates of the cropped image in the initial photo |
| `rectangleCoordinates`            | `Object` see usage | No | Object to predefine an area to crop (an already detected image for example) |
| `initialImage`            | `String` | Yes | Base64 encoded image you want to be cropped |
| `height`            | `Number` | Yes | Height of the image (will probably disappear in the future |
| `width`            | `Number` | Yes | Width of the image (will probably disappear in the future |
| `overlayColor`            | `String` | No | Color of the cropping area overlay  |
| `overlayStrokeColor`            | `String` | No | Color of the cropping area stroke  |
| `overlayStrokeWidth`            | `Number` | No | Width of the cropping area stroke  |
| `handlerColor`            | `String` | No | Color of the handlers  |


## Usage

```javascript
import CustomCrop from 'react-native-perspective-image-cropper';

class CropView extends Component {
  componentWillMount() {
    const image = 'base64ImageString';
    Image.getSize(image, (width, height) => {
      this.setState({
        imageWidth: width,
        imageHeight: height,
        initialImage: image,
        rectangleCoordinates: {
          topLeft: { x: 10, y: 10 },
          topRight: { x: 10, y: 10 },
          bottomRight: { x: 10, y: 10 },
          bottomLeft: { x: 10, y: 10 },
        },
      });
    });
  }

  updateImage(image, newCoordinates) {
    this.setState({
      image,
      rectangleCoordinates: newCoordinates
    });
  }

  crop() {
    this.customCrop.crop();
  }

  render() {
    return (
      <View>
        <CustomCrop
          updateImage={this.updateImage.bind(this)}
          rectangleCoordinates={this.state.rectangleCoordinates}
          initialImage={this.state.initialImage}
          height={this.state.imageHeight}
          width={this.state.imageWidth}
          ref={(ref) => this.customCrop = ref}
          overlayColor="rgba(18,190,210, 1)"
          overlayStrokeColor="rgba(20,190,210, 1)"
          handlerColor="rgba(20,150,160, 1)"
        />
        <TouchableOpacity onPress={this.crop.bind(this)}>
          <Text>CROP IMAGE</Text>
        </TouchableOpacity>
      </View>
    );
  }
}
```
