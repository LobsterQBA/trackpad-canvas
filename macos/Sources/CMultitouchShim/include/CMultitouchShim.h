#ifndef CMULTITOUCH_SHIM_H
#define CMULTITOUCH_SHIM_H

typedef struct { float x, y; } MTShimPoint;
typedef struct { MTShimPoint pos, vel; } MTShimReadout;

typedef struct {
    int frame;
    double timestamp;
    int identifier;
    int state;
    int fingerID;
    int handID;
    MTShimReadout normalized;
    float size;
    int zero1;
    float angle;
    float majorAxis;
    float minorAxis;
    MTShimReadout absolute;
    int zero2[2];
    float density;
} MTShimTouch;

typedef void *MTShimDeviceRef;
typedef int (*MTShimContactCallback)(int device, MTShimTouch *touches, int numTouches,
                                     double timestamp, int frame);
typedef MTShimDeviceRef (*MTShimCreateDefaultFn)(void);
typedef void (*MTShimRegisterContactFrameCallbackFn)(MTShimDeviceRef, MTShimContactCallback);
typedef void (*MTShimDeviceStartFn)(MTShimDeviceRef, int);
typedef void (*MTShimDeviceStopFn)(MTShimDeviceRef);
typedef void (*MTShimDeviceReleaseFn)(MTShimDeviceRef);

#endif

