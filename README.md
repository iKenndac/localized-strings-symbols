# localized-strings-symbols

An SPM and Xcode build plugin for creating Swift symbols for localized string keys.

## What It Does

This is a very simple build plugin that creates Swift structures representing the keys in your app's `.strings` files. This allows the compiler to check you're referencing valid strings, and provides some nice features for format tokens.

The plugin creates two "routes" for each key in your `.strings` file:

- As an extension on `LocalizedStringKey` for use with SwiftUI

- As a struct named after the table name (i.e., `Localizable`) for use with everything else.

If you follow the SwiftUI convention of including format specifiers in your keys, the generated structures will automatically include strongly-typed functions for the format values. In SwiftUI contexts(i.e., extensions on `LocalizedStringKey`), functions are also provided for inlining SF Symbols via `Image` parameters.

For example, given the following strings file, named `Localizable.strings`:

```
"NameAlertTitle %@" = "Hello %@!";
"OKButtonTitle" = "OK";
```

The output will provide symbols that can be used as such:

``` swift
// In a SwiftUI context
VStack {
    Text(.nameAlertTitle(formatValue: "Daniel"))
    Text(.nameAlertTitle(imageValue: Image(systemName: "exclamationmark.triangle")))
}

// In a non-SwiftUI context
let alertTitle: String = Localizable.nameAlertTitle(formatValue: "Daniel")
```

## Limitations

Right now this is a _very_ basic plugin, and as such there are a number of limitations and requirements. If you'd like to help make it better, pull requests are welcome! 

- Strings file keys are expected to be in CamelCase, with format specifiers space-separated at the end of the key matching in number to the ones in the value (for example: `"NameAlertTitle %@" = "Hello %@!";`). 

- Only the `%@` format specifier is supported.

- Multiple format specifiers aren't very intelligent in the `LocalizedStringKey` output. For example, if you have two specifiers and want one format value to be a `String` and the other an `Image`, that isn't currently provided for.

- In the `LocalizedStringKey` output, only functions with `String` and `Image` parameters are generated.

- It doesn't appear that build plug-ins can find out what a project's development language is, so instead the plug-in chooses the `.strings` file with the most keys in it as the source.

## How To Use

### Xcode Projects

**Important:** Build plugins like this one require Xcode 14 beta 3 or higher.

First, add the package to your project by clicking the **+** button at the bottom of the package list in your project's **Package Dependencies** tab, then pasting the package's URL into the search field: `https://github.com/iKenndac/localized-strings-symbols.git`.

Then, in the following dialog, make sure the package is added as a dependency to the relevant target(s).

Finally, go to your target(s) **Build Phases** tab, and in the **Run Build Tool Plug-ins** phase, add the plug-in.

<img src="Documentation%20Images/xcode-target-settings.png" width="492">

### SPM Packages

First, add the package to your dependencies list:

``` swift
…
dependencies: [
    .package(url: "https://github.com/iKenndac/localized-strings-symbols.git", branch: "main")
],
…
```

Then, add the dependency and the plugin to your target(s):

``` swift
…
    .target(
        name: "MyCoolPackage",
        dependencies: [.product(name: "Generate Strings File Symbols", package: "localized-strings-symbols")],
        plugins: ["Generate Strings File Symbols"]
    ),
…
```
