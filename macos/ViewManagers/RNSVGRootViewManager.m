/**
 * Copyright (c) 2015-present, Horcrux.
 * All rights reserved.
 *
 * This source code is licensed under the MIT-style license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <React/RCTBridge.h>
#import <React/RCTUIManager.h>
#import "RNSVGRootViewManager.h"
#import "RNSVGRootView.h"

@implementation RNSVGRootViewManager

RCT_EXPORT_MODULE()

- (NSView *)view
{
    return [RNSVGRootView new];
}

RCT_EXPORT_VIEW_PROPERTY(bbWidth, RNSVGLength*)
RCT_EXPORT_VIEW_PROPERTY(bbHeight, RNSVGLength*)
RCT_EXPORT_VIEW_PROPERTY(minX, CGFloat)
RCT_EXPORT_VIEW_PROPERTY(minY, CGFloat)
RCT_EXPORT_VIEW_PROPERTY(vbWidth, CGFloat)
RCT_EXPORT_VIEW_PROPERTY(vbHeight, CGFloat)
RCT_EXPORT_VIEW_PROPERTY(align, NSString)
RCT_EXPORT_VIEW_PROPERTY(meetOrSlice, RNSVGVBMOS)
RCT_EXPORT_VIEW_PROPERTY(tintColor, NSColor)

RCT_EXPORT_METHOD(toDataURL:(nonnull NSNumber *)reactTag callback:(RCTResponseSenderBlock)callback)
{
    [self.bridge.uiManager addUIBlock:^(RCTUIManager *uiManager, NSDictionary<NSNumber *,NSView *> *viewRegistry) {
        __kindof NSView *view = viewRegistry[reactTag];
        if ([view isKindOfClass:[RNSVGRootView class]]) {
            RNSVGRootView *svg = view;
            callback(@[[svg getDataURL]]);
        } else {
            RCTLogError(@"Invalid svg returned frin registry, expecting RNSVGRootView, got: %@", view);
        }
    }];
}

@end
