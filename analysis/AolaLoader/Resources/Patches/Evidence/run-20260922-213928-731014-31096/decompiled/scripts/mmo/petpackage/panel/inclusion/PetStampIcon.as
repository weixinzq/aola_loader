package mmo.petpackage.panel.inclusion
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.events.MouseEvent;
   import mmo.common.DisplayUtil;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.IPetDataService;
   import mmo.interfaces.pet.data.PetDataServiceEvent;
   import mmo.play.activity.activitylimiter.ActivityId;
   import mmo.play.activity.activitylimiter.ActivityLimiter;
   import mmo.play.activity.helper.Panel_Helper;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol2565")]
   public class PetStampIcon extends MovieClip
   {
      
      public var btnpetstamp:SimpleButton;
      
      private var _petDataService:IPetDataService = ServiceContainer.getService(IPetDataService) as IPetDataService;
      
      public function PetStampIcon()
      {
         super();
         this.init();
      }
      
      private function init() : void
      {
         this.addEventListener(MouseEvent.CLICK,this.onClickIcon);
         this._petDataService.addEventListener(PetDataServiceEvent.ON_HIGHTES_BATTLE_EFF_UPDATE,this.onHighestBEUpdated);
         this.refreshIconView();
      }
      
      private function onHighestBEUpdated(param1:PetDataServiceEvent) : void
      {
         this.refreshIconView();
      }
      
      private function refreshIconView() : void
      {
         var _loc3_:* = null;
         var _loc1_:Boolean = Boolean(ActivityLimiter.checkIsOpen(ActivityId.PET_STAMP));
         var _loc2_:int = int(ActivityLimiter.getActivityOpenBe(ActivityId.PET_STAMP));
         if(_loc1_)
         {
            this.mouseChildren = true;
            DisplayUtil.clearFilters(this);
            _loc3_ = "亚比印记";
         }
         else
         {
            this.mouseChildren = false;
            DisplayUtil.applyGray(this);
            _loc3_ = "战斗力到达" + _loc2_ + "才推荐开启这个功能哦！";
         }
         TipsManager.getInstance().replaceTips(this,_loc3_);
      }
      
      private function onClickIcon(param1:MouseEvent) : void
      {
         var _loc2_:String = param1.target.name;
         if(_loc2_ == "btnpetstamp")
         {
            this.showPetStampPanel();
         }
      }
      
      private function showPetStampPanel() : void
      {
         ModalDialogManager.getInstance().clearAll();
         var _loc1_:String = "activityres/activity160304/stampsys/stampsys";
         var _loc2_:String = "mmo.activity160304.stampsys.panel.StampSysMain";
         Panel_Helper.loadResAndShow(_loc1_,_loc2_);
      }
      
      public function dispose() : void
      {
         this._petDataService.removeEventListener(PetDataServiceEvent.ON_HIGHTES_BATTLE_EFF_UPDATE,this.onHighestBEUpdated);
      }
   }
}

