//
//  AppToolkitObjC.h
//  Appkit
//
//  Created by Ilya Kuznetsov on 12/20/19.
//  Copyright © 2019 Ilya Kuznetsov. All rights reserved.
//

#ifndef AppToolkitObjC_h
#define AppToolkitObjC_h

typedef void (^ATHandleOperation)(id operation);
typedef void (^ATCompletion)(id object, NSError *requestError);
typedef void (^ATProgress)(double progress);

#endif /* AppToolkitObjC_h */
