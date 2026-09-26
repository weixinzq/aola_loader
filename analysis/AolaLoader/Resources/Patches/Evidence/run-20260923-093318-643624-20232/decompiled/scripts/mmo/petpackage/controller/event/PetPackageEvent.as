package mmo.petpackage.controller.event
{
   import flash.events.Event;
   
   public class PetPackageEvent extends Event
   {
      
      public static const PET_JUMP_FIRST_TAB:String = "PETPACKAGEEVENT_PET_JUMP_FIRST_TAB";
      
      public static const PET_JUMP_SECOND_TAB:String = "PETPACKAGEEVENT_PET_JUMP_SECOND_TAB";
      
      public static const PET_INFO_TAB_CHANGED:String = "PETPACKAGEEVENT_PET_INFO_TAB_CHANGED";
      
      public static const PET_CARD_SHOW_STATUS_CHANGED:String = "PETPACKAGEEVENT_PET_CARD_SHOW_STATUS_CHANGED";
      
      public static const EQUIP_SHOW_KEY:String = "PETPACKAGEEVENT_PET_CARD_SHOW_STATUS";
      
      public static const PET_PANEL_CLOSED:String = "PetPackageEvent_PET_PANEL_CLOSED";
      
      public static const PET_SERVICE_DISPOSE:String = "PetPackageEvent_PET_SERVICE_DISPOSE";
      
      public static const PET_SETPRI:String = "PetPackageEvent_PET_SETPRI";
      
      public static const PET_SINGLE_HEALTH:String = "PetPackageEvent_PET_SINGLE_HEALTH";
      
      public static const PET_FOLLOW_CHANGE:String = "PetPackageEvent_PET_FOLLOW_CHANGE";
      
      public static const PET_RIDE_CHANGE:String = "PetPackageEvent_PET_RIDE_CHANGE";
      
      public static const PET_BACK2STORE:String = "PetPackageEvent_PET_BACK2STORE";
      
      public static const PET_DETAIL_UPDATE:String = "PetPackageEvent_PET_DETAIL_UPDATE";
      
      public static const PET_GO_2_SINGLE_PM:String = "PetPackageEvent_PET_GO_2_SINGLE_PM";
      
      public static const PET_CLOTHES_BIGVIEW:String = "PetPackageEvent_PET_CLOTHES_BIGVIEW";
      
      public static const ONLY_UPDATE_PANEL:String = "PetPackageEvent_Panel_Update";
      
      public static const ON_OPEN_HUAN_DONG:String = "PetPackageEvent_Open_Huan_Dong";
      
      public static const ON_CLOSE_HUAN_DONG:String = "PetPackageEvent_Close_Huan_Dong";
      
      public static const ON_OPEN_HAI_BAO:String = "PETPACKAGEEVENT_OPEN_HAI_BAO";
      
      public static const ON_CLOSE_HAI_BAO:String = "PETPACKAGEEVENT_CLOSE_HAI_BAO";
      
      public static const ON_SKIN_PRE_MOVIE_FINISH:String = "ON_SKIN_PRE_MOVIE_FINISH";
      
      private var _params:Object = {};
      
      public function PetPackageEvent(param1:String, param2:Object = null)
      {
         super(param1);
         this._params = param2 == null ? {} : param2;
      }
      
      public function get params() : Object
      {
         return this._params;
      }
   }
}

