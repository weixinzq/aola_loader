package mmo.petpackage.panel.inclusion
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.DisplayUtil;
   import mmo.interfaces.pet.data.BargainPetConfig;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.peticon.PetIconContainer;
   import mmo.interfaces.pet.peticon.PetIconEvent;
   import mmo.interfaces.pet.peticon.PetIconType;
   import mmo.petpackage.controller.event.PetPackageEvent;
   import mmo.petpackage.controller.event.PetPackageEventDispatcher;
   import mmo.petpackage.controller.helper.BargainSkillIconHelper;
   import mmo.petpackage.data.PetDetailDataMap;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol3029")]
   public class BargainIcon extends MovieClip
   {
      
      public var iconContainer:MovieClip;
      
      public var skillIconContainer:MovieClip;
      
      public var txtSkillDetail:TextField;
      
      public var txtSkillName:TextField;
      
      private var petInfo:PetBriefInfo;
      
      private var petIcon:PetIconContainer;
      
      public function BargainIcon()
      {
         super();
         this.gotoAndStop(1);
         this.addEventListener(MouseEvent.ROLL_OVER,this.showTips);
         this.addEventListener(MouseEvent.ROLL_OUT,this.removeTips);
         PetPackageEventDispatcher.instance.addEventListener(PetPackageEvent.PET_DETAIL_UPDATE,this.onSelectedData);
      }
      
      private function showTips(param1:MouseEvent) : void
      {
         if(this.petInfo == null)
         {
            return;
         }
         if(!BargainPetConfig.isBargainPet(this.petInfo.raceId))
         {
            return;
         }
         this.gotoAndStop(2);
         var _loc2_:int = int(BargainPetConfig.getAfterBargainRaceId(this.petInfo.raceId));
         this.loadIcon(_loc2_);
         this.refreshBargainSkill(this.petInfo);
      }
      
      private function loadIcon(param1:int) : void
      {
         this.petIcon = new PetIconContainer(param1,PetIconType.LARGE,false);
         this.petIcon.addEventListener(PetIconEvent.ON_ICON_LOADED,this.onLoadIcon);
         this.petIcon.startLoad();
      }
      
      private function removeTips(param1:MouseEvent) : void
      {
         this.gotoAndStop(1);
      }
      
      private function onLoadIcon(param1:PetIconEvent) : void
      {
         var _loc2_:PetIconContainer = param1.currentTarget as PetIconContainer;
         _loc2_.removeEventListener(PetIconEvent.ON_ICON_LOADED,this.onLoadIcon);
         if(this.currentFrame == 1)
         {
            return;
         }
         DisplayUtil.stopAndRemove(this.petIcon);
         var _loc3_:Number = Sprite(this.iconContainer).width;
         var _loc4_:Number = Sprite(this.iconContainer).height;
         this.petIcon = _loc2_;
         Sprite(this.iconContainer).addChild(this.petIcon);
         DisplayUtil.stop(this.petIcon);
         DisplayUtil.scaleDisplay(this.petIcon,_loc3_,_loc4_);
         DisplayUtil.middleDisplay(this.petIcon,_loc3_,_loc4_);
      }
      
      private function refreshBargainSkill(param1:PetBriefInfo) : void
      {
         var _loc2_:TextField = this.getChildByName("txtSkillName") as TextField;
         _loc2_.mouseEnabled = false;
         _loc2_.text = BargainPetConfig.getBargainSkillName(param1.raceId);
         var _loc3_:TextField = this.getChildByName("txtSkillDetail") as TextField;
         _loc3_.mouseEnabled = false;
         _loc3_.text = BargainPetConfig.getBargainSkillDetail(param1.raceId,param1.changeViewLevel);
         var _loc4_:Sprite = this.getChildByName("skillIconContainer") as Sprite;
         var _loc5_:Number = _loc4_.width;
         var _loc6_:Number = _loc4_.height;
         DisplayUtil.clearChildren(_loc4_);
         BargainSkillIconHelper.loadIcon(param1.raceId,_loc4_,_loc5_,_loc6_);
      }
      
      private function onSelectedData(param1:PetPackageEvent) : void
      {
         this.petInfo = PetDetailDataMap.instance.getPetDetailInfo(param1.params.id);
         this.removeTips(null);
         this.visible = BargainPetConfig.isBargainPet(this.petInfo.raceId);
      }
      
      public function dispose() : void
      {
         this.petInfo = null;
         this.removeEventListener(MouseEvent.ROLL_OVER,this.showTips);
         this.removeEventListener(MouseEvent.ROLL_OUT,this.removeTips);
         PetPackageEventDispatcher.instance.removeEventListener(PetPackageEvent.PET_DETAIL_UPDATE,this.onSelectedData);
      }
   }
}

