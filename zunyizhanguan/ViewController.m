//
//  ViewController.m
//  zunyizhanguan
//
//  Created by mac on 14-6-24.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController
{
    int select;
    UIButton* lastButton;
    UIImage *imageSelected;
    UIImage *imageUnSelected;
    MyUDP *udp;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    select = -1;
    lastButton = nil;
    imageSelected = [UIImage imageNamed:@"selected.png"];
    imageUnSelected = [UIImage imageNamed:@"unselected.png"];
    if (imageSelected == nil || imageUnSelected == nil) {
        NSLog(@"load image faild");
    }
    udp = [[MyUDP alloc] init];
    NSError *strerr = nil;
    if(![udp StartUdpCenter:1024 error:&strerr])
    {
        NSLog(@"Start udp error! code %d,info %@",strerr.code,strerr.domain);
    }

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)btselectchange:(UIButton *)sender {
    if (lastButton) {
        [lastButton setBackgroundImage:imageUnSelected forState:UIControlStateNormal];
    }
    
    lastButton = sender;
    [sender setBackgroundImage:imageSelected forState:UIControlStateNormal];
    select = sender.tag;
}

- (IBAction)Play:(id)sender {
    if (select == -1) {
        return;
    }
    
    Byte buf[256] = {0};
    char pstr[] = "测试.wmv";
    buf[0] = 0x1;
    buf[2] = strlen(pstr);
    memcpy(&buf[3], pstr, strlen(pstr));
    NSLog(@"%d",select);
    switch (select) {
        case 0://一起
        {
            buf[1] = 0x2;
        }
            break;
        case 1://沙盘
        {
            buf[1] = 0x0;
        }
            break;
        case 2://环幕
        {
            buf[1] = 0x1;
        }
        default:
            break;
    }
    [udp BroadUdp:buf Length:strlen(pstr) + 3 IP:"192.168.1.255" Port:5045];
}

- (IBAction)Pause:(id)sender {
    if (select == -1) {
        return;
    }
    
    Byte buf[256] = {0};
    buf[0] = 0x3;
    
    switch (select) {
        case 0://一起
        {
            buf[1] = 0x2;
        }
            break;
        case 1://沙盘
        {
            buf[1] = 0x0;
        }
            break;
        case 2://环幕
        {
            buf[1] = 0x1;
        }
        default:
            break;
    }
    [udp BroadUdp:buf Length:2 IP:"192.168.1.255" Port:5045];
}

- (IBAction)Stop:(id)sender {
    if (select == -1) {
        return;
    }
    
    Byte buf[256] = {0};
    buf[0] = 0x4;
    
    
    switch (select) {
        case 0://一起
        {
            buf[1] = 0x2;
        }
            break;
        case 1://沙盘
        {
            buf[1] = 0x0;
        }
            break;
        case 2://环幕
        {
            buf[1] = 0x1;
        }
        default:
            break;
    }
    
    [udp BroadUdp:buf Length:2 IP:"192.168.1.255" Port:5045];
}

- (IBAction)ValueChanged:(UISlider *)sender {
    int value = sender.value;
    value -= 10000;
    Byte buf[256] = {0};
    buf[0] = 0x2;
    memcpy(&buf[2], &value, 4);
    switch (select) {
        case 0://一起
        {
            buf[1] = 0x2;
        }
            break;
        case 1://沙盘
        {
            buf[1] = 0x0;
        }
            break;
        case 2://环幕
        {
            buf[1] = 0x1;
        }
        default:
            break;
    }
    [udp BroadUdp:buf Length:6 IP:"192.168.1.255" Port:5045];

}

@end
