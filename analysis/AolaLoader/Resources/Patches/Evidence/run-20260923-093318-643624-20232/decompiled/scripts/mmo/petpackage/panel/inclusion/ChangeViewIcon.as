package mmo.petpackage.panel.inclusion
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.DisplayUtil;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.AoYiConfig;
   import mmo.interfaces.pet.data.IPetSkillMesService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PetChangeViewConfig;
   import mmo.interfaces.pet.peticon.PetIconContainer;
   import mmo.interfaces.pet.peticon.PetIconEvent;
   import mmo.interfaces.pet.peticon.PetIconType;
   import mmo.interfaces.pet.pm.data.custom.PMSkill;
   import mmo.interfaces.pet.pm.operation.IPMSkillInfo;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.interfaces.xinghui.XinghuiPetType;
   import mmo.petpackage.controller.event.PetPackageEvent;
   import mmo.petpackage.controller.event.PetPackageEventDispatcher;
   import mmo.petpackage.data.PetDetailDataMap;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol1247")]
   public class ChangeViewIcon extends MovieClip implements IDispose
   {
      
      public var iconContainer:MovieClip;
      
      public var spSkill0:MovieClip;
      
      public var spSkill1:MovieClip;
      
      public var spSkill2:MovieClip;
      
      public var spSkill3:MovieClip;
      
      private var petInfo:PetBriefInfo;
      
      private var petIcon:PetIconContainer;
      
      private var attIconArr:Array = [];
      
      private var _pmSvr:IPMService = ServiceContainer.getService(IPMService) as IPMService;
      
      public function ChangeViewIcon()
      {
         super();
         addFrameScript(0,this.frame1);
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
         if(!PetChangeViewConfig.isChangeViewPet(this.petInfo.raceId) || Boolean(AoYiConfig.isAoYiPet(this.petInfo.raceId)) || Boolean(this._pmSvr.getOperationPM(this.petInfo.raceId).pmData.isDegeneratorPM()))
         {
            return;
         }
         this.gotoAndStop(2);
         var _loc2_:int = int(PetChangeViewConfig.getTargetRaceId(this.petInfo.raceId));
         this.loadIcon(_loc2_);
         this.showSkill(_loc2_);
      }
      
      private function showSkill(param1:int) : void
      {
         var _loc5_:Sprite = null;
         var _loc6_:PMSkill = null;
         var _loc7_:TextField = null;
         var _loc8_:TextField = null;
         var _loc9_:TextField = null;
         var _loc10_:IPetSkillMesService = null;
         var _loc2_:IPMService = ServiceContainer.getService(IPMService) as IPMService;
         var _loc3_:Vector.<IPMSkillInfo> = _loc2_.getOperationPM(param1).getDefaultSkills();
         var _loc4_:int = 0;
         while(_loc4_ < 4)
         {
            _loc5_ = this.getChildByName("spSkill" + _loc4_.toString()) as Sprite;
            TipsManager.getInstance().removeTips(_loc5_);
            if(_loc4_ >= _loc3_.length)
            {
               _loc5_.visible = false;
            }
            else
            {
               _loc5_.visible = true;
               _loc6_ = _loc2_.customData.pmSkillMap.getSkill(_loc3_[_loc4_].skillId);
               _loc7_ = _loc5_.getChildByName("txtName") as TextField;
               _loc7_.mouseEnabled = false;
               _loc7_.text = _loc6_.newCnName;
               _loc8_ = _loc5_.getChildByName("txtHurt") as TextField;
               _loc8_.mouseEnabled = false;
               _loc8_.text = _loc6_.power == -1 ? "-" : _loc6_.power.toString();
               _loc9_ = _loc5_.getChildByName("txtPower") as TextField;
               _loc9_.mouseEnabled = false;
               _loc9_.text = _loc6_.allPP.toString() + "/" + _loc6_.allPP.toString();
               DisplayUtil.stopAndRemove(this.attIconArr[_loc4_]);
               _loc10_ = ServiceContainer.getService(IPetSkillMesService) as IPetSkillMesService;
               this.attIconArr[_loc4_] = _loc10_.getSkillAttributeIcon(_loc6_.attributeType);
               this.attIconArr[_loc4_].x = 17;
               this.attIconArr[_loc4_].y = 8;
               _loc5_.addChild(this.attIconArr[_loc4_]);
               TipsManager.getInstance().addComplexTips(_loc5_,_loc6_.newCnName,_loc6_.clientDesc);
            }
            _loc4_++;
         }
      }
      
      private function loadIcon(param1:int) : void
      {
         DisplayUtil.stopAndRemove(this.petIcon);
         this.petIcon = new PetIconContainer(param1,PetIconType.LARGE,false);
         this.petIcon.addEventListener(PetIconEvent.ON_ICON_LOADED,this.onLoadIcon);
         this.petIcon.startLoad();
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
      
      private function removeTips(param1:MouseEvent) : void
      {
         this.gotoAndStop(1);
      }
      
      private function onSelectedData(param1:PetPackageEvent) : void
      {
         this.petInfo = PetDetailDataMap.instance.getPetDetailInfo(param1.params.id);
         this.removeTips(null);
         this.visible = Boolean(PetChangeViewConfig.isChangeViewPet(this.petInfo.raceId)) && !AoYiConfig.isAoYiPet(this.petInfo.raceId) && !this._pmSvr.getOperationPM(this.petInfo.raceId).pmData.isDegeneratorPM() && !XinghuiPetType.isChuanShuo(this._pmSvr.getOperationPM(this.petInfo.raceId).pmData.getXinghuiType());
      }
      
      public function dispose() : void
      {
         this.petInfo = null;
         this.removeEventListener(MouseEvent.ROLL_OVER,this.showTips);
         this.removeEventListener(MouseEvent.ROLL_OUT,this.removeTips);
         PetPackageEventDispatcher.instance.removeEventListener(PetPackageEvent.PET_DETAIL_UPDATE,this.onSelectedData);
      }
      
      internal function frame1() : *
      {
         stop();
      }
   }
}

