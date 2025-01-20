// ===============================================
// Part 2: Hook SLTwitterRequest (TwitterSettings, sociald)
// ===============================================

// Original function pointers for SLTwitterRequest
static id (*orig_SL_initWithURL)(id self, SEL _cmd, NSURL *url, NSDictionary *params, int method) = NULL;
static void (*orig_SL_performJSONRequestWithHandler)(id self, SEL _cmd, void (^handler)(NSData*,NSHTTPURLResponse*,NSError*)) = NULL;
static NSURL* (*orig_SL_URL)(id self, SEL _cmd) = NULL;
static NSURLRequest* (*orig_SL_signedURLRequest)(id self, SEL _cmd) = NULL;