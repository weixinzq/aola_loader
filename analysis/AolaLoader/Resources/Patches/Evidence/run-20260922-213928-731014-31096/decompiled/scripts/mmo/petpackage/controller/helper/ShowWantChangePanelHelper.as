package mmo.petpackage.controller.helper
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.SimpleButton;
   import mmo.common.DisplayUtil;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.IPetDataService;
   import mmo.play.activity.helper.Panel_Helper;
   
   public class ShowWantChangePanelHelper
   {
      
      private static const BUTTON_NAMES:Array = ["btnjingdouhow","btnhowlevel","btnhowgenius","btnhowcharactor","btnhowpetcard3"];
      
      private static const EFF_NEEDS:Array = [0,0,0,0,0,0];
      
      public function ShowWantChangePanelHelper()
      {
         super();
      }
      
      public static function setButtonState(param1:DisplayObjectContainer) : void
      {
         var _loc5_:SimpleButton = null;
         var _loc2_:IPetDataService = ServiceContainer.getService(IPetDataService) as IPetDataService;
         var _loc3_:int = int(_loc2_.getHighestBattleEff());
         var _loc4_:int = 0;
         while(_loc4_ < BUTTON_NAMES.length)
         {
            _loc5_ = param1.getChildByName(BUTTON_NAMES[_loc4_]) as SimpleButton;
            if(_loc5_ != null)
            {
               _loc5_.useHandCursor = true;
               TipsManager.getInstance().removeTips(_loc5_);
               DisplayUtil.clearFilters(_loc5_);
               if(_loc3_ < EFF_NEEDS[_loc4_])
               {
                  _loc5_.useHandCursor = false;
                  DisplayUtil.applyGray(_loc5_);
                  TipsManager.getInstance().addTips(_loc5_,"战斗力达" + EFF_NEEDS[_loc4_] + "开启！");
               }
            }
            _loc4_++;
         }
      }
      
      public static function dealButton(param1:DisplayObject) : void
      {
         var _loc2_:int = int(BUTTON_NAMES.indexOf(param1.name));
         if(_loc2_ < 0)
         {
            return;
         }
         if(param1 is SimpleButton && SimpleButton(param1).useHandCursor == true)
         {
            Panel_Helper.loadResAndShow("activityres/activity201225/iwantstrengthen/iwantstrengthen_code","mmo.activity201225.iwantstrengthen.panel.IWS_MainPl",{"tab":_loc2_ + 1});
         }
      }
   }
}

