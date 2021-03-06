//
//  DJIFlyZoneManager.h
//  DJISDK
//
//  Copyright © 2016, DJI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MKCircle.h>
#import <DJISDK/DJIFlyZoneInformation.h>
#import <DJISDK/DJIBaseProduct.h>

NS_ASSUME_NONNULL_BEGIN

@class DJIFlyZoneManager;
@class DJIIndividualUnlockZone;


/**
 *  This protocol provides the delegate method to receive updated fly zone
 *  information.
 */
@protocol DJIFlyZoneDelegate <NSObject>


/**
 *  Called when the latest fly zone status is received.
 *  
 *  @param manager An instance of `DJIFlyZoneManager`.
 *  @param state An enum value of `DJIFlyZoneState`.
 */
 -(void)flyZoneManager:(DJIFlyZoneManager *)manager didUpdateFlyZoneState:(DJIFlyZoneState)state;

@end


/**
 *  Fly Zone Manager gives information about nearby fly zones, and APIs to unlock
 *  zones that can be unlocked. Depending on location, there are three types of fly
 *  zones possible:
 *   - NFZ: Cylinder or truncated cone volume where flight is restricted
 *   - Poly: Fly zone that consists of one or more sub fly zones that are cylinders
 *  or complex volumes with different height limitations. A height limitation of 0
 *  means flight is completely restricted. This is used by Mavic, Phantom 4 Pro,
 *  Inspire 2 and Phantom 4
 *   - GEO: Cylinder volume with four levels of restriction:
 *      - Warning Zones - no restriction
 *      - Enhanced warning zones - Flight restricted, can be unlocked for
 *          flight when the user logs into their DJI account
 *      - Authorization zones - Flight restricted, can be unlocked for
 *          flight when the user logs into their DJI account and the account
 *          has been authorized to unlock authorization zones.
 *      - Restricted zones - Flight restricted
 *   On the Phantom 3, Inspire 1, M100, M600, A3/N3 series of products there can
 *  also be  a 4km buffer around an NFZ fly zone where flight height is limited to
 *  120m. If the  aircraft is in such a buffer area, `DJIFlyZoneState` will be
 *  `DJIFlyZoneStateInWarningZoneWithHeightLimitation`.
 */
@interface DJIFlyZoneManager : NSObject


/**
 *  Delegate to receive the updated status.
 */
@property(nonatomic, weak) id<DJIFlyZoneDelegate> delegate;


/**
 *  `YES` if an aircraft is connected with flight controller firmware that  supports
 *  Individual Unlock Zones. Aircraft that support Individual unlock  zones are also
 *  able to disable unlocked fly zones temporarily.
 */
@property(nonatomic, readonly) BOOL isIndividualUnlockZoneSupported;


/**
 *  The fly zone database state in the firmware of the aircraft. The SDK will
 *  compare the version of the database on the aircraft against the latest one
 *  online. When the aircraft database is  out-of-date, the user should use DJI GO
 *  or Assistant 2 to update the firmware.
 */
@property(nonatomic, readonly) DJIFlyZoneDatabaseState databaseState;


/**
 *  The version of the fly zone database in the firmware of the aircraft. It is
 *  `nil` if `databaseState` is  `DJIFlyZoneDatabaseStateInitializing`.
 */
@property(nonatomic, readonly, nullable) NSString *databaseVersion;


/**
 *  Gets all the fly zones within 20km of the aircraft. During simulation, this
 *  method is available only when the aircraft location is within 50km of
 *  (37.460484, -122.115312) or within 50km of (22.5726, 113.8124499). Use of the
 *  geographic information provided by DJIFlyZoneManager is restricted. Refer to the
 *  DJI Developer Policy.
 *  
 *  @param infos Array of `DJIFlyZoneInformation` objects.
 *  @param error Error retrieving the value.
 *  @param completion Completion block to receive the result.
 */
-(void)getFlyZonesInSurroundingAreaWithCompletion:(void (^_Nonnull)(NSArray<DJIFlyZoneInformation*> *_Nullable infos, NSError* _Nullable error))completion;


/**
 *  `YES` to enable GEO system. By default, if the GEO system is available at the
 *  aircraft's  location, the GEO system will be enabled.  This setting can be
 *  changed when the aircraft is in the air, however it will not take effect until
 *  the aircraft lands. When the GEO system is disabled, the aircraft  reverts to
 *  the NFZ (No Fly Zone) system. This interface may be deprecated in the future.
 *  
 *  @param enabled `YES` to enable GEO system.
 *  @param completion The execution block with the returned execution result.
 */
-(void)setGEOSystemEnabled:(BOOL)enabled withCompletion:(DJICompletionBlock)completion;


/**
 *  `YES` to enable GEO system. By default, if the GEO system is available at the
 *  aircraft's  location, the GEO system will be enabled.  This setting can be
 *  changed when the aircraft is in the air, however it will not take effect until
 *  the aircraft lands. When the GEO system is disabled, the aircraft  reverts to
 *  the NFZ (No Fly Zone) system. This interface may be deprecated in the future.
 *  
 *  @param enabled `YES` if the GEO system is enabled.
 *  @param error Error retrieving the value.
 *  @param completion Completion block to receive the result.
 */
-(void)getGEOSystemEnabled:(void (^_Nonnull)(BOOL enabled, NSError *_Nullable error))completion;


/**
 *  Gets a list of unlocked fly zones of the authorized account from the server.
 *  The list contains the fly zones unlocked by the Flight Planner
 *  (http://www.dji.com/flysafe/geo-system#planner), and the fly zones unlocked
 *  during flight using DJI GO or any DJI Mobile SDK based application.
 *  
 *  @param infos The array of the `DJIFlyZoneInformation` objects.
 *  @param error Error retrieving the value.
 *  @param completion Completion block to receive the result.
 */
-(void)getUnlockedFlyZonesWithCompletion:(void (^_Nonnull)(NSArray<DJIFlyZoneInformation*> *_Nullable infos, NSError* _Nullable error))completion;


/**
 *  Unlocks the selected fly zones. This method can be used to unlock  enhanced
 *  warning and authorization zones. After unlocking the zones, flight will be
 *  unrestricted in those zones until the unlock expires.  The unlocking record will
 *  be linked to the user's account and will  be accessible to DJI GO and other DJI
 *  Mobile SDK based applications.
 *  
 *  @param flyZoneIDs The IDs of EnhancedWarningZones or AuthorizedWarningZones.
 *  @param completion The execution block with the returned execution result.
 */
-(void)unlockFlyZones:(NSArray<NSNumber *> *_Nonnull)flyZoneIDs withCompletion:(DJICompletionBlock)completion;


/**
 *  When an Individual Unlock Zone is approved, the approval and zone information
 *  needs to be downloaded from the Fly Zone server and uploaded to the aircraft.
 *  For each product connection state change, or network connection state change
 *  this  is done automatically. However, if the Individual Unlock Zone is approved
 *  and needs  to be uploaded to the aircraft without changing the network
 *  connectivity or product  connectivity state, then this method can be used to
 *  force the  Individual Unlock  Zone update. For this method to work, the user
 *  must already be logged in. Individual  Unlock Zones are associated with an
 *  aircraft serial number, and so, to upload to  the aircraft, the right aircraft
 *  must also be connected. This method can only be  used when
 *  `isIndividualUnlockZoneSupported` is `YES`.
 *  
 *  @param completion `completion block` to receive the result.
 */
-(void)loadIndividualUnlockZonesFromServerWithCompletion:(DJICompletionBlock)completion;


/**
 *  Gets the Individual Unlock zones currently on the aircraft. This method can
 *  only be used when `isIndividualUnlockZoneSupported`  is `YES`.
 *  
 *  @param zones Array of `DJIIndividualUnlockZone` objects.
 *  @param error Error retrieving the value.
 *  @param completion Completion block to receive the result.
 */
-(void)getIndividualUnlockZonesWithCompletion:(void (^_Nonnull)(NSArray<DJIIndividualUnlockZone *> *_Nullable zones, NSError *_Nullable error))completion;


/**
 *  Enables an Individual Unlock zones that is on the aircraft. All Individual
 *  Unlock zones  on the aircraft can be retrieved with
 *  `getIndividualUnlockZonesWithCompletion`.  At any time, only one Individual
 *  Unlock zone can be enabled. Enabling an Individual Unlock  zone will disable the
 *  previously enabled zone. This method can only be used when
 *  `isIndividualUnlockZoneSupported` is `YES`.
 *  
 *  @param zone Individual Unlock zone to enabled. If `zone` is `nil`, only the previously enabled zone  will be disabled.
 *  @param completion `completion block` to receive the result.
 */
-(void)enableIndividualUnlockZone:(DJIIndividualUnlockZone *_Nullable)zone
                   withCompletion:(DJICompletionBlock)completion;


/**
 *  Gets the currently enabled Individual Unlock zone. This method can only be used
 *  when `isIndividualUnlockZoneSupported` is `YES`.
 *  
 *  @param zone The enabled Individual Unlock zone. `nil` if no zones are enabled.
 *  @param error Error if there is any.
 *  @param completion Completion block to receive the result.
 */
-(void)getEnabledIndividualUnlockZoneWithCompletion:(void (^_Nonnull)(DJIIndividualUnlockZone *_Nullable zone, NSError *_Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
