# Microsoft Authentication Library for iOS

The MSAL library for iOS gives your app the ability to connect your users through [Microsoft Azure Active Directory](https://azure.microsoft.com/en-us/services/active-directory/) and [Microsoft Accounts](https://account.microsoft.com/), using industry standard OAuth2 and OpenID Connect.

This is a customized version of the original one provided by Microsoft and **is not supported and/or endorsed by Microsoft in any way**.
Since I do not offer any kind of support whatsoever, if you are looking to begin working with this library, always refer to the [original repository](https://github.com/AzureAD/microsoft-authentication-library-for-objc).

If you're still interested in this fork, go straight to the next paragraph.

## Why this fork
The main reason why this fork is born is to fix the incompatibility between this library and the Azure B2C authentication system. However, going ahead with it I realized that I needed to directly expose to my application the _refreshToken_, hence I decided not to merge this fork and keep it as a separated project.

You should not use this fork, unless you are looking for the following added features:

* Direct access to the _refreshToken_: even though this might sound as a security issue to someone, there are specific cases where this is needed.

If you're still reading and you really want to use this fork, you should also bear in mind these few things:

* This library **is not supported** neither by Microsoft or me. I do not provide any kind of assistance in using it and I do not guarantee that it will be kept in sync with any change to the Microsoft Cloud or the original library.

## Usage
Keeping in mind all of the things that you should have read before **(if you didn't, please do)**, the preferred way to use this library is `Carthage`.

### Installing

Just add the following to your `Cartfile`:

```
github "MrAsterisco/MSAL" "master"
```

If you don't have `Carthage` in your project, refer to [this guide](https://github.com/Carthage/Carthage#adding-frameworks-to-an-application) to learn how to install and configure it.

Once you have the MSAL library in your project, you can import it with the following line:

```swift
import MSAL
```

### Acquiring a Token for the first time
To initiate an authentication session, you need to initialize a `MSALPublicClientApplication` using your _Client ID_ and the _Authority_, that you can get using the Azure portal:

```swift
let application = try MSALPublicClientApplication.init(clientId: <# clientId #>, authority: <# authority #>)
```

The first time that your application needs to authenticate the user, make a call to the `acquireToken` method:

```swift
application.acquireToken(forScopes: [<# an array of scopes #>]) { (result, error) in
	if let result = result {
		let accessToken = result.accessToken
		let userIdentifier = result.user.userIdentifier()
		<# use the accessToken #>
	} else if let error = error {
		<# handle errors #>
	}
}
```

_Note: if you are using Azure B2C, you must pass the Client ID as the one of the scopes._

The `acquireToken` call will automatically open a `SFSafariViewController` with the correct Microsoft login page (or your customized portal, if you have one). Once the user has successfully completed the login procedure, the `SFSafariViewController` will redirect to your app using an URL-schema that you must have defined in the Azure portal. To be able to handle this redirect, your app should define the following in the `Info.plist` file.

```xml
<key>CFBundleURLTypes</key>
<array>
	<dict>
		<key>CFBundleTypeRole</key>
		<string>Editor</string>
		<key>CFBundleURLName</key>
		<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
		<key>CFBundleURLSchemes</key>
		<array>
			<string>msalyour-client-id-here</string>
		</array>
	</dict>
</array>
```

Furthermore, your `AppDelegate` instance should pass these types of redirect URIs to the MSAL library, using the following code:

```swift
func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
	// If your app also handles other URL Types, just make a switch on url.scheme

	MSALPublicClientApplication.handleMSALResponse(url)
	return true
}
```

### Caching
To know if the user is logged-in, your application should store the user identifier. **Do not manually cache either the accessToken or the refreshToken**: this is done for you automatically by the library.

The user identifier, as the name says, stores a unique reference to the logged-in user and can be used to acquire a token at any time.

### Acquiring a Token silently
When your application needs a token, you should always refer to the MSAL library to get one. However, if you already have a user identifier somewhere, you will want the app to acquire it without asking the user to login once again.

To do this, use the `acquireTokenSilent` method:

```swift
let user = try! application.user(forIdentifier: <# userIdentifier #>)
application.acquireTokenSilent(forScopes: [<# scopes #>], user: user, completionBlock: { (result, error) in
	if let result = result {
		let accessToken = result.accessToken
		<# use the accessToken #>
	}
	else if let error = error {
		if ((error as NSError).code == MSALErrorCode.interactionRequired.rawValue) {
			<# handle interaction required error #>
		}
		else {
			<# handle other errors #>
		}
	}
})
```

Most of the times, this call will just return the _accessToken_ in cache. Every once in a while, that token will expire and the library will automatically refresh it using the _refreshToken_.

Sometimes, the Microsoft Authentication system might require to show the login window once again, for various reasons (this won't happen often and should not affect your user experience in any way): when this happens, the `MSALErrorCode.interactionRequired` will be thrown.

### Getting the refresh token

**Note: do not mess around with the refreshToken, if you don't know what you're doing. You should always consider it just like a password.**

Using the user identifier that you have previously cached, you can gather the associated _refreshToken_ with the following code:

```swift
let refreshToken = try! application.refreshToken(forUserIdentifier: <# userIdentifier #>)
```

### Logging out
To logout a user, use the `remove` method on the `MSALPublicClientApplication`.

```swift
try application.remove(user)
```

Of course, you should also erase your application cache, to make sure that the next time the interactive login window will be triggered.

## Help and Support
The guide above is the most detailed tutorial on how to integrate and use the MSAL library that I could find. I have extended the Microsoft tutorial (which lacks of most of the precious information that you'll need while working with MSAL) with my personal experience.

Anyway, I **do not provide** any kind of commercial or free support for this library. If you have problems and you want to discuss them with me, open an issue in this repository: I usually answer within a few hours, a day top.

If you have issues not directly related to this fork, please always **refer to the original version of the library** provided by Microsoft.

### Contribute
If you want to contribute and improve the MSAL library, refer to the original repository by Microsoft.

Anyway, if you think that your changes are more related to my version, feel free to fork this repository and, eventually, do a pull request.