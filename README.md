#Handmade SOAP Framework
Handmade SOAP Framework is a simple framework to organize SOAP exchange between web service and your app. Unlike frameworks which are generated from a wsdl file, in this case you, by yourself, define all necessary details for your specific server. That is perfectly fine as very likely you don't need at once all SOAP actions available for your service. Probably APIs which are offered by a server are significant system operations. In most cases each such operation assumes self-sufficient functionality in your app as well. That means while development you can go through development defining each operation when it is required. Using such self-forged SOAP actions you promote comprehension of your app. Handmade SOAP framework is a tool to quickly build an environment of self-forged SOAP actions for your app.

##Overview
The framework is designed to be similar in using to NSURLRequest and NSURLConnection. A role of NSURLConnection is given to HSFClient which does all networking. HSFAction is a abstract class with a role of NSURLRequest. You must subclass HSFAction and override all abstract methods. It is recommended at first create a general(for your app) HSFAction subclass where you define XML SOAP document and HTTP header fields. Then you could subclass this general subclass for each specific SOAP action, where you only define a name of SOAP action and parameters to send within SOAP XML document.

##Code Example
```  objective-c
// Define General subclass.
@interface GeneralAction : HSFAction
@end
@implementation GeneralAction
-(NSDictionary*)HTTPHeaderFields
{
    return @{CONTENT_TYPE:@"text/xml; charset=utf-8",
        @"SOAPAction":[NSString stringWithFormat:@"http://tempuri.org/IMobileEApproval/%@",self.SOAPAction]
        };
}

-(NSString*)SOAPEnvelopeHead
{
    return @"<?xml version=\"1.0\" encoding=\"utf-8\"?><soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns=\"http://tempuri.org/\"><soap:Body>";
}
-(NSString*)SOAPEnvelopeTail
{
    return @"</soap:Body></soap:Envelope>";
}
@end

// Define self-forged action
@interface GetUserJobsAction : GeneralAction
@property (strong,nonatomic) NSString* userId;
@property (nonatomic) NSUInteger maxJobs;
@end
@implementation GetUserJobsAction
-(NSDictionary*)SOAPParameters
{
    return @{@"userID":self.userId,@"maxJobs":[NSNumber numberWithUnsignedLong:self.maxJobs]};
    //That will become <userID>self.userId</userID><maxJobs>self.maxJobs</maxJobs>
}
-(NSString*)SOAPAction
{
    return @"GetUserJobs";
}
@end

//Somewhere in code
GetUserJobsAction *jobsAction = [[GetUserJobsAction alloc] initWithURL:self.url];
jobsAction.userId = @"1232bbsq";
jobsAction.maxJobs = 10;
HSFClient *client = [[HSFClient alloc] initWithAction:jobsAction delegate:self startImmediately:NO];
[client loadAsynchronously];

//Handle delegate callbacks via
-(void)client:(HSFClient*)client didReceiveUnit:(HSFNode*)rootNode; // Units are determine using unitTags.
-(void)client:(HSFClient *)client didReceiveEntireResponse:(HSFNode *)rootNode;

//HSFNode - essentially is a tree structure representing received XML structure.
```

##Features
* Extract and parse specific tags from a response which is not finished downloading. I.e. process units in turns without waiting a whole XML document downloaded.
* Basic Authentication Challenge handling.
* Async and sync options of loading.
* HSFNode to NSDictionary if one-one possible.
* Automatic request repeating until timeout exceeded.
* Low level access to SOAP protocol.

##Notes
A very first release, used only in demoes. Improvements are presumed.
* HSFrameworkProject - Handmade SOAP Framework Xcode project.
* HSFramework - Handmade SOAP Framework source files to import into an application.

