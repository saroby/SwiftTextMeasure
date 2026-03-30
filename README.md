# SwiftTextMeasure

**SwiftTextMeasure** is a lightweight and efficient Swift library for
measuring and laying out text with precision.

It is designed for developers who need accurate text measurement for
custom UI rendering, layout engines, or advanced typography handling in
iOS, macOS, and beyond.

> ⚡️ Built with inspiration from the techniques used in
> https://github.com/chenglou/pretext

------------------------------------------------------------------------

## ✨ Features

-   📏 Precise text measurement (width, height, bounding rect)
-   ⚡️ Fast and predictable layout calculations
-   🧩 Simple and minimal API surface
-   🧵 Designed for performance-critical rendering paths
-   🖋️ Works with attributed strings and typography settings
-   📱 Supports UIKit / AppKit environments

------------------------------------------------------------------------

## 🧠 Background

SwiftTextMeasure is **based on the core ideas and techniques from
https://github.com/chenglou/pretext**, a high-performance text
measurement library originally developed for efficient UI rendering.

The goal of this project is to bring similar performance characteristics
and architectural ideas into the Swift ecosystem, making it easier to:

-   Measure text without relying on heavyweight layout systems
-   Avoid unnecessary rendering overhead
-   Build custom layout engines with predictable results

------------------------------------------------------------------------

## 📦 Installation

### Swift Package Manager

Add the package to your project:

``` swift
.package(url: "https://github.com/saroby/SwiftTextMeasure.git", from: "1.0.0")
```

Then include it in your target:

``` swift
.target(
    name: "YourTarget",
    dependencies: ["SwiftTextMeasure"]
)
```

------------------------------------------------------------------------

## 🚀 Usage

### Basic Example

``` swift
import SwiftTextMeasure

let text = "Hello, world!"
let font = UIFont.systemFont(ofSize: 16)

let size = TextMeasure.measure(
    text: text,
    font: font,
    constrainedTo: CGSize(width: 200, height: .greatestFiniteMagnitude)
)

print(size)
```

------------------------------------------------------------------------

### Attributed Text

``` swift
let attributedString = NSAttributedString(
    string: "Styled text",
    attributes: [
        .font: UIFont.boldSystemFont(ofSize: 18)
    ]
)

let size = TextMeasure.measure(
    attributedString: attributedString,
    constrainedTo: CGSize(width: 200, height: .greatestFiniteMagnitude)
)
```

------------------------------------------------------------------------

## 🏗️ Design Goals

SwiftTextMeasure focuses on:

-   Deterministic layout results
-   Minimal overhead
-   Separation from rendering
-   Composable text measurement primitives

------------------------------------------------------------------------

## 📊 When to Use

Use SwiftTextMeasure when you need:

-   Custom layout systems (e.g., chat UI, editors)
-   High-performance scrolling lists
-   Text pre-calculation (before rendering)
-   Fine-grained typography control

------------------------------------------------------------------------

## 📄 License

MIT License
