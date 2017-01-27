//
//  UsageHandler.m
//  dodicall
//
//  Copyright (C) 2016, Telco Cloud Trading & Logistic Ltd
//
//  This file is part of dodicall.
//  dodicall is free software : you can redistribute it and / or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  dodicall is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with dodicall.If not, see <http://www.gnu.org/licenses/>.

#import "UsageHandler.h"
#import <mach/mach.h>
#import "UiLogger.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface UsageHandler()

@property (strong, nonatomic) RACSignal *TimerSignal;
@property (strong, nonatomic) NSNumber *Logging;

@end


@implementation UsageHandler

- (instancetype)init {
    self = [super init];
    if(self) {
        self.Logging = @(NO);
        self.TimerSignal = [RACSignal interval:60 onScheduler:[RACScheduler schedulerWithPriority:RACSchedulerPriorityDefault]];
        [self BindTimer];
        
    }
    return self;
}

- (void) BindTimer {
    [[self.TimerSignal combineLatestWith:RACObserve(self, Logging)] subscribeNext:^(RACTuple *x) {
        NSNumber *isLogEnabled = [x second];
        
        if(isLogEnabled && [isLogEnabled boolValue])
            [UsageHandler LogUsage];
    }];
}

- (void) StartScheduledLogging {
    self.Logging = @(YES);
}

- (void) StopScheduledLogging {
    self.Logging = @(NO);
}

+ (void) LogUsage {
    [UiLogger WriteLogDebug:[UsageHandler GetLogString]];
}

+ (NSString *) GetLogString {
    float cpu = [UsageHandler GetCpuUsage];
    vm_size_t fMemory = [UsageHandler GetFreeMemory];
    vm_size_t uMemory = [UsageHandler GetDirtyMemory];
    
    NSString *fMemoryString = [UsageHandler ConvertBytesToString:fMemory];
    NSString *uMemoryString = [UsageHandler ConvertBytesToString:uMemory];
    
    return [NSString stringWithFormat:@"System usage: %@ / %@ / %.1f\uFF05", uMemoryString, fMemoryString, cpu];
}

+ (NSString *)ConvertBytesToString:(mach_vm_size_t)bytes {
    NSString *returnString = [NSString new];
    
    NSArray *suffix = @[@"B", @"kB", @"mB", @"gB"];
    int i;
    
    double bytesCopy = bytes;
    double result = 0.0;
    
    
    for (i=0; i<suffix.count-1 && bytesCopy>=1024;i++, bytesCopy/=1024) {
        result = bytesCopy/1024;
    }
    
    returnString = [NSString stringWithFormat:@"%.1f %@", result, suffix[i]];
    return returnString;
}

+ (vm_size_t) GetDirtyMemory {
    struct mach_task_basic_info info;
    mach_msg_type_number_t size = MACH_TASK_BASIC_INFO_COUNT;
    
    kern_return_t kerr = task_info(mach_task_self(), MACH_TASK_BASIC_INFO, (task_info_t)&info, &size);
    
    if (kerr != KERN_SUCCESS)
        return 0;
    
    kerr = vm_deallocate(mach_task_self(), (vm_offset_t)MACH_TASK_BASIC_INFO, size);
    assert(kerr == KERN_SUCCESS);
    
    return info.resident_size;
}

+ (vm_size_t) GetFreeMemory {
    mach_port_t host_port = mach_host_self();
    mach_msg_type_number_t host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    vm_size_t pagesize;
    vm_statistics_data_t vm_stat;
    
    host_page_size(host_port, &pagesize);
    (void) host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size);
    
    return vm_stat.free_count * pagesize;
}

+ (float) GetCpuUsage {
    kern_return_t kr;
    task_info_data_t tinfo;
    mach_msg_type_number_t task_info_count;
    
    task_info_count = TASK_INFO_MAX;
    kr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)tinfo, &task_info_count);
    if (kr != KERN_SUCCESS) {
        return -1;
    }
    
    task_basic_info_t      basic_info;
    thread_array_t         thread_list;
    mach_msg_type_number_t thread_count;
    
    thread_info_data_t     thinfo;
    mach_msg_type_number_t thread_info_count;
    
    thread_basic_info_t basic_info_th;
    uint32_t stat_thread = 0;
    
    basic_info = (task_basic_info_t)tinfo;
    
    kr = task_threads(mach_task_self(), &thread_list, &thread_count);
    if (kr != KERN_SUCCESS) {
        return -1;
    }
    if (thread_count > 0)
        stat_thread += thread_count;
    
    long tot_sec = 0;
    long tot_usec = 0;
    float tot_cpu = 0;
    int j;
    
    for (j = 0; j < thread_count; j++)
    {
        thread_info_count = THREAD_INFO_MAX;
        kr = thread_info(thread_list[j], THREAD_BASIC_INFO,
                         (thread_info_t)thinfo, &thread_info_count);
        if (kr != KERN_SUCCESS) {
            return -1;
        }
        
        basic_info_th = (thread_basic_info_t)thinfo;
        
        if (!(basic_info_th->flags & TH_FLAGS_IDLE)) {
            tot_sec += basic_info_th->user_time.seconds + basic_info_th->system_time.seconds;
            tot_usec += basic_info_th->user_time.microseconds + basic_info_th->system_time.microseconds;
            tot_cpu += basic_info_th->cpu_usage / (float)TH_USAGE_SCALE * 100.0;
        }
        
    }
    
    kr = vm_deallocate(mach_task_self(), (vm_offset_t)thread_list, thread_count * sizeof(thread_t));
    assert(kr == KERN_SUCCESS);
    
    return tot_cpu;
}

@end
