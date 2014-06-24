//
//  MyUDP.m
//  zunyizhanguan
//
//  Created by mac on 14-6-24.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "MyUDP.h"
#include <arpa/inet.h>//inet_addr只为使用这个
#include <sys/socket.h>
#include <netinet/in.h>
#include <fcntl.h>
#include <unistd.h>

@implementation MyUDP
{
    CFSocketRef _cfSocket;
}
@synthesize delegate = _delegate;


- (void)sendData:(unsigned char*)buf Length:(int)ilen IP:(char*)ipaddr Port:(int)port

// Called by both -sendData: and the server echoing code to send data
// via the socket.  addr is nil in the client case, whereupon the
// data is automatically sent to the hostAddress by virtue of the fact
// that the socket is connected to that address.
{
    struct sockaddr_in serv_addr;
    bzero(&serv_addr, sizeof(serv_addr));
    serv_addr.sin_family = AF_INET;
    serv_addr.sin_port = htons(port);
    serv_addr.sin_addr.s_addr = inet_addr(ipaddr);
    int bytesWritten = sendto(CFSocketGetNative(self->_cfSocket), buf, ilen, 0, (struct sockaddr*)&serv_addr, sizeof(serv_addr));
    int err = 0;
    
    if (bytesWritten < 0) {
        err = errno;
    } else  if (bytesWritten == 0) {
        err = EPIPE;
    } else {
        // We ignore any short writes, which shouldn't happen for UDP anyway.
        assert( (NSUInteger) bytesWritten == ilen );
        err = 0;
    }
    
    if (err == 0) {
        if ( (self.delegate != nil) && [self.delegate respondsToSelector:@selector(echo:didSendData:toAddress:)] ) {
            NSData * data = [NSData dataWithBytes:buf length:ilen];
            NSData * addr = [NSData dataWithBytes:(struct sockaddr_in*)&serv_addr length:sizeof(serv_addr)];
            [self.delegate echo:self didSendData:data toAddress:addr];
        }
    } else {
        if ( (self.delegate != nil) && [self.delegate respondsToSelector:@selector(echo:didFailToSendData:toAddress:error:)] ) {
            NSData * data = [NSData dataWithBytes:buf length:ilen];
            NSData * addr = [NSData dataWithBytes:(struct sockaddr_in*)&serv_addr length:sizeof(serv_addr)];

            [self.delegate echo:self didFailToSendData:data toAddress:addr error:[NSError errorWithDomain:NSPOSIXErrorDomain code:err userInfo:nil]];
        }
    }
}



- (void)readData
{
    int                     err;
    int                     sock;
    struct sockaddr_storage addr;
    socklen_t               addrLen;
    uint8_t                 buffer[1000];
    ssize_t                 bytesRead;
    
    sock = CFSocketGetNative(self->_cfSocket);
    assert(sock >= 0);
    
    addrLen = sizeof(addr);
    bytesRead = recvfrom(sock, buffer, sizeof(buffer), 0, (struct sockaddr *) &addr, &addrLen);
    if (bytesRead < 0) {
        err = errno;
    } else if (bytesRead == 0) {
        err = EPIPE;
    } else {
        NSData *    dataObj;
        NSData *    addrObj;
        
        err = 0;
        
        dataObj = [NSData dataWithBytes:buffer length:(NSUInteger) bytesRead];
        assert(dataObj != nil);
        addrObj = [NSData dataWithBytes:&addr  length:addrLen  ];
        assert(addrObj != nil);
        
        // Tell the delegate about the data.
        
        if ( (self.delegate != nil) && [self.delegate respondsToSelector:@selector(echo:didReceiveData:fromAddress:)] ) {
            [self.delegate echo:self didReceiveData:dataObj fromAddress:addrObj];
        }
        
        // Echo the data back to the sender.
        
    }

}

static void SocketReadCallback(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info)
// This C routine is called by CFSocket when there's data waiting on our
// UDP socket.  It just redirects the call to Objective-C code.
{
    MyUDP*  obj;
    
    obj = (__bridge MyUDP *) info;
    assert([obj isKindOfClass:[MyUDP class]]);
    
#pragma unused(s)
    assert(s == obj->_cfSocket);
#pragma unused(type)
    assert(type == kCFSocketReadCallBack);
#pragma unused(address)
    assert(address == nil);
#pragma unused(data)
    assert(data == nil);
    
    [obj readData];
}



- (BOOL)StartUdpCenter:(int) port error:(NSError **)errorPtr

{
    signal(SIGPIPE, SIG_IGN);
    int udp_fd;
    udp_fd = -1;
    int err = 0;
    if ((udp_fd = socket(AF_INET, SOCK_DGRAM, IPPROTO_IP)) == -1) {
        err = errno;
    }
    
    //-----如果只用于upd广播不需要接收数据，那么以下这段代码是可以不需要的
    struct sockaddr_in  addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_len         = sizeof(addr);
    addr.sin_family      = AF_INET;
    addr.sin_port        = htons(port);
    addr.sin_addr.s_addr = INADDR_ANY;
    err = bind(udp_fd, (const struct sockaddr *) &addr, sizeof(addr));//打开接收功能
    if (err == -1) {
        err = errno;
    }
    //-------------------
    
    
    int flags;
    flags = fcntl(udp_fd,F_GETFL,0);
    err = fcntl(udp_fd,F_SETFL, flags|O_NONBLOCK);
    int so_broadcast = 1;//1是打开,0是关闭
    err = setsockopt(udp_fd, SOL_SOCKET, SO_BROADCAST, &so_broadcast,
                     sizeof(so_broadcast));
    if (err == -1) {
        err = errno;
    }
    
    //----如果只用于upd广播不需要接收数据，那么以下这段代码是可以不需要的
    const CFSocketContext   context = { 0, (__bridge void *)(self), NULL, NULL, NULL };
    CFRunLoopSourceRef      rls;
    
    self->_cfSocket  = CFSocketCreateWithNative(NULL, udp_fd, kCFSocketReadCallBack, SocketReadCallback, &context);
    
    assert( CFSocketGetSocketFlags(self->_cfSocket) & kCFSocketCloseOnInvalidate);
    udp_fd = -1;//标明创建成功，让系统自己关闭socket
    
    rls = CFSocketCreateRunLoopSource(NULL, self->_cfSocket, 0);
    assert(rls != NULL);
    
    CFRunLoopAddSource(CFRunLoopGetCurrent(), rls, kCFRunLoopDefaultMode);
    
    CFRelease(rls);

    int junk;
    if (udp_fd != -1) { //创建socket后中间出现了任何错误
        junk = close(udp_fd);
        assert(junk == 0);
    }
    assert((err == 0) && (self->_cfSocket != NULL));
    
    //-----
    if ( (self->_cfSocket == NULL) && (errorPtr != NULL) ) {
        *errorPtr = [NSError errorWithDomain:NSPOSIXErrorDomain code:err userInfo:nil];
    }
    
    return (err == 0);

}

- (void)BroadUdp:(unsigned char*)buf Length:(int)ilen IP:(char*)ipaddr Port:(int)port
{
    struct sockaddr_in serv_addr;
    bzero(&serv_addr, sizeof(serv_addr));
    serv_addr.sin_family = AF_INET;
    serv_addr.sin_port = htons(port);//5045
    serv_addr.sin_addr.s_addr = inet_addr(ipaddr);
    sendto(CFSocketGetNative(self->_cfSocket), buf, ilen, 0, (struct sockaddr*)&serv_addr, sizeof(serv_addr));
}

- (void)BroadStartUpComputer:(unsigned char*)buf Length:(int)ilen
{
    struct sockaddr_in serv_addr;
    bzero(&serv_addr, sizeof(serv_addr));
    serv_addr.sin_family = AF_INET;
    serv_addr.sin_port = htons(2705);
    serv_addr.sin_addr.s_addr = inet_addr("192.168.1.255");
    sendto(CFSocketGetNative(self->_cfSocket), buf, ilen, 0, (struct sockaddr*)&serv_addr, sizeof(serv_addr));
}


@end
