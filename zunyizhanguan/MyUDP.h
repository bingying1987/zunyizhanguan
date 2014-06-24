//
//  MyUDP.h
//  zunyizhanguan
//
//  Created by mac on 14-6-24.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol UDPEchoDelegate;
@interface MyUDP : NSObject
@property (nonatomic, weak, readwrite) id<UDPEchoDelegate> delegate;
- (BOOL)StartUdpCenter:(int) port error:(NSError **)errorPtr
;//建立UDP,并绑定一个端口用于接收，并打开广播(具备发和收的功能,不掉用connect),调用了bind还调用connect表示只接收与发送 指定ip地址指定端口的数据,服务器和客户端调用bind表示只通过这个端口接收发送数据，而不是随机打开一个端口发送数据。 客户端只发送不接收时 不需要调用bind.
//实际上udp并不怎么区分客户端与服务器因为都可以调用bind,与connect.bind表示只通过固定端口进行接收发送.当不需要接收时
//可以不调用，系统发送就会随机使用端口.调用了connect就可以使用send,recv,write,read. 无需像recvfrom,sendto那样指定ip和端口。但是调用connect后发送和接收都只能时那个固定ip的数据。
- (void)BroadUdp:(unsigned char*)buf Length:(int)ilen IP:(char*)ipaddr Port:(int)port;//广播数据到指定端口
- (void)BroadStartUpComputer:(unsigned char*)buf Length:(int)ilen;//广播远程唤醒命令实现开机
- (void)sendData:(unsigned char*)buf Length:(int)ilen IP:(char*)ipaddr Port:(int)port;//往指定ip端口发送数据
@end

@protocol UDPEchoDelegate <NSObject>

@optional

// In all cases an address is an NSData containing some form of (struct sockaddr),
// specifically a (struct sockaddr_in) or (struct sockaddr_in6).

- (void)echo:(MyUDP *)echo didReceiveData:(NSData *)data fromAddress:(NSData *)addr;
// Called after successfully receiving data.  On a server object this data will
// automatically be echoed back to the sender.
//
// assert(echo != nil);
// assert(data != nil);
// assert(addr != nil);

- (void)echo:(MyUDP *)echo didReceiveError:(NSError *)error;
// Called after a failure to receive data.
//
// assert(echo != nil);
// assert(error != nil);

- (void)echo:(MyUDP *)echo didSendData:(NSData *)data toAddress:(NSData *)addr;
// Called after successfully sending data.  On the server side this is typically
// the result of an echo.
//
// assert(echo != nil);
// assert(data != nil);
// assert(addr != nil);

- (void)echo:(MyUDP *)echo didFailToSendData:(NSData *)data toAddress:(NSData *)addr error:(NSError *)error;
// Called after a failure to send data.
//
// assert(echo != nil);
// assert(data != nil);
// assert(addr != nil);
// assert(error != nil);

- (void)echo:(MyUDP *)echo didStartWithAddress:(NSData *)address;
// Called after the object has successfully started up.  On the client addresses
// is the list of addresses associated with the host name passed to
// -startConnectedToHostName:port:.  On the server, this is the local address
// to which the server is bound.
//
// assert(echo != nil);
// assert(address != nil);

- (void)echo:(MyUDP *)echo didStopWithError:(NSError *)error;
// Called after the object stops spontaneously (that is, after some sort of failure,
// but now after a call to -stop).
//
// assert(echo != nil);
// assert(error != nil);

@end
