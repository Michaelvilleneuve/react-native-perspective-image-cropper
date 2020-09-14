# React Native Document Scanner + image cropper 📐🖼

Document in progress...

##### React Native Document Scanner

## Installation 🚀🚀

`$ npm install https://github.com/tomasvarga/react-native-document-scanner.git --save`

`$ react-native link react-native-perspective-image-cropper`

This library uses react-native-svg, you must install it too. See https://github.com/react-native-community/react-native-svg for more infos.

#### Android Only

If you do not already have openCV installed in your project, add this line to your `settings.gradle`

```
include ':openCVLibrary310'
project(':openCVLibrary310').projectDir = new File(rootProject.projectDir,'../node_modules/react-native-perspective-image-cropper/android/openCVLibrary310')
```

## Crop image

- First get component ref

```javascript
<CustomCrop ref={ref => (this.customCrop = ref)} />
```

- Then call :

```javascript
this.customCrop.current.crop();
```
