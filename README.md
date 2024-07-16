# FaceLivenessDetection

FaceLivenessDetection is a Swift package that provides a framework for detecting face liveness using the front camera with depth data. The package uses AVFoundation and Vision frameworks to capture video and depth data, and perform face detection and liveness prediction.

## Features

- Face detection with depth data
- Real-time face orientation analysis
- Liveness prediction based on captured images
- Integration with SwiftUI and UIKit

## Demo

[![Liveness Demo](https://github.com/9count/FaceLivenessDetection/assets/82346532/b05c7c44-ff84-4511-bd31-2ca606d060eb)](https://github.com/9count/FaceLivenessDetection/assets/82346532/7fdf3f4e-6d74-4f57-a333-2bf614512ade)

## Usage

```swift
struct ContentView: View {
    var body: some View {
        // Embedding the FaceLivenessDetectionView inside a your view.

        FaceLivenessDetectionView(
            timeInterval: 3, // Set the time interval for the fake progress UI.
            onCompletion: handleCompletion // Your completion handler to process the result.
        )
    }

    /// Handles the completion of the liveness detection.
    /// - Parameter result: The result of the liveness detection, either successful with data or a failure with an error.
    func handleCompletion(result: Result<LivenessDataModel, LivenessDetectionError>) {
        switch result {
        case .success(let dataModel):
            print("Detection successful: \(dataModel)")
            // Handle success case, update UI or data model accordingly.
        case .failure(let error):
            print("Detection failed with error: \(error)")
            // Handle error, show alert or error message to the user.
        }
    }
}
```

## Requirements

- iOS 15.0+
- Xcode 15.0+
- Swift 5.0+

## Installation

### Swift Package Manager

You can integrate FaceLivenessDetection into your project using Swift Package Manager. To add the package to your Xcode project, follow these steps:

1. Open your Xcode project.
2. Go to `File` > `Add Packages`.
3. Enter the repository URL: `https://github.com/9count/FaceLivenessDetection`.
4. Choose the latest version or specify the version you need.
5. Add the package to your project.
