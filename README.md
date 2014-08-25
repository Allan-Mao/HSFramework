#Handmade SOAP Framework
Handmade SOAP Framework is a simple framework to organize a SOAP exchange between a web service and your app. Unlike frameworks which are generated from a WSDL file, in this case you, by yourself, define all necessary details for your specific server. That is perfectly fine as very likely you don't need at once all SOAP actions available for your service. Probably APIs which are offered by a server are significant system operations. In most cases each such operation assumes a lot of functionality in your app as well. That means while development you can define each operation when it is required. Using such self-forged SOAP actions you promote comprehension of your app. Handmade SOAP framework is a tool to quickly build an environment of self-forged SOAP actions for your app.

##Overview
The framework is designed to be similar in using to NSURLRequest and NSURLConnection. A role of NSURLConnection is given to HSFCatcher (HSFClient is a factory for it) which does all networking. HSFAction is a abstract class with a role of NSURLRequest. You must subclass HSFAction and override all abstract methods. It is recommended at first to create a general(for your app) HSFAction subclass where you define all commonalities of all actions of the service. Then you could subclass this general subclass for each specific SOAP action, where you only define a name of SOAP action and parameters to send within SOAP XML document.

##Features
* Encapsulate SOAP actions with OOP.
* Low level access to SOAP protocol.
* Extract and parse specific tags from a response which is not yet fully downloaded.
* Get bytes from a specific tag while response is coming to your device (like streaming), e.g. for audioContent.
* XML is converted to a tree of HSFNodes, which are capable to be cast to NSDictionary. 
* Response downloading progress notification.
* Notifications to manage networkActivityIndicator.
* Unified error handling for error and parse errors.
* Automatic request repeating until timeout exceeded.
* Basic Authentication Challenge handling.

##Notes
* HSFrameworkProject - Handmade SOAP Framework Xcode project.
* HSFramework - Handmade SOAP Framework source files to import into an application.
* See [HSFYillioDemo](https://github.com/ilnar-aliullov/HSFYillioDemo) project for code examples.
* Project is fully unit tested.
