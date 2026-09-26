package mmo.petpackage.panel.inclusion.petdetailinfo
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.text.TextField;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.miraclepet.IMiraclePetDataService;
   import mmo.interfaces.miraclepet.MiraclePetBreakData;
   import mmo.interfaces.pet.data.SkillInfo;
   import mmo.interfaces.pet.pm.data.custom.PMSkill;
   import mmo.interfaces.pet.pm.operation.IPMSkillInfo;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.petpackage.panel.inclusion.PetAttrIcon;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol1273")]
   public class MiraclePetSkillComponent extends Sprite
   {
      
      public var attrcontainer:MovieClip;
      
      public var passiveskill:MovieClip;
      
      public var txtname:TextField;
      
      public var txtpower:TextField;
      
      public var txtpp:TextField;
      
      private var _pmService:IPMService;
      
      private var _petAttrIcon:PetAttrIcon;
      
      private var _seriesIndex:int;
      
      private var _skillInfo:SkillInfo;
      
      private var _miraclePetId:int;
      
      private var _skillIndex:int;
      
      public function MiraclePetSkillComponent()
      {
         super();
         this._pmService = ServiceContainer.getService(IPMService) as IPMService;
         this.init();
      }
      
      private static function getPetSkillDec(param1:int, param2:*) : String
      {
         var _loc4_:int = 0;
         var _loc5_:PMSkill = null;
         var _loc6_:IMiraclePetDataService = null;
         var _loc7_:Vector.<IPMSkillInfo> = null;
         var _loc3_:IPMService = ServiceContainer.getService(IPMService) as IPMService;
         if(param2 == 2)
         {
            _loc6_ = ServiceContainer.getService(IMiraclePetDataService) as IMiraclePetDataService;
            _loc4_ = int(_loc6_.getMiraclePetInfo(param1).passiveSkillIdList[0]);
            _loc5_ = _loc3_.customData.pmSkillMap.getSkill(_loc4_);
         }
         else
         {
            _loc7_ = _loc3_.getOperationPM(param1).getCommonSkillList();
            _loc5_ = _loc3_.customData.pmSkillMap.getSkill(_loc7_[param2].skillId);
         }
         return "威力:" + _loc5_.power.toString() + "\n" + _loc5_.clientDesc;
      }
      
      private static function seriesIndexToLvStr(param1:int) : String
      {
         if(param1 == 4)
         {
            return "LVMAX";
         }
         return "LV:" + String(param1 + 1);
      }
      
      private function init() : void
      {
         this._petAttrIcon = new PetAttrIcon();
         var _loc1_:Sprite = this.getChildByName("attrcontainer") as Sprite;
         _loc1_.addChild(this._petAttrIcon.view);
      }
      
      public function refresh(param1:int, param2:int, param3:SkillInfo, param4:Boolean = false) : *
      {
         if(param3 == null)
         {
            return;
         }
         this._miraclePetId = param1;
         this._skillIndex = param2;
         var _loc5_:IMiraclePetDataService = ServiceContainer.getService(IMiraclePetDataService) as IMiraclePetDataService;
         var _loc6_:MiraclePetBreakData = _loc5_.getMiraclePetBreakDataByRaceId(this._miraclePetId);
         this._seriesIndex = _loc6_.breakSeriers.indexOf(this._miraclePetId);
         this._skillInfo = param3;
         var _loc7_:int = int(this._pmService.customData.pmSkillMap.getSkill(param3.id).attributeType);
         this._petAttrIcon.refresh(_loc7_);
         var _loc8_:PMSkill = this._pmService.customData.pmSkillMap.getSkill(param3.id);
         this.txtname.text = _loc8_.newCnName;
         this.txtpower.text = _loc8_.power < 0 ? "—" : _loc8_.power.toString();
         if(_loc8_.allPP == 0)
         {
            this.txtpp.text = "--/--";
         }
         else
         {
            this.txtpp.text = param3.canUseTimes + "/" + _loc8_.allPP;
         }
         DisplayObject(this["passiveskill"]).visible = param4;
         var _loc9_:String = _loc8_.newCnName + this.getSkillType(_loc8_.attackType);
         TipsManager.getInstance().replaceComplexTips(this,_loc9_,this.getTips(),0,9,-50);
      }
      
      private function getSkillType(param1:int) : String
      {
         switch(param1)
         {
            case 0:
               return "(普通攻击)";
            case 1:
               return "(特殊攻击)";
            case 2:
               return "(属性攻击)";
            default:
               return "";
         }
      }
      
      private function getTips() : String
      {
         var _loc1_:String = null;
         if(this._seriesIndex == 4)
         {
            _loc1_ = this.getNowLvTips();
         }
         else
         {
            _loc1_ = this.getNowLvTips() + "\n---------\n" + this.getNextLvTips() + "\n--------\n" + this.getMaxLvTips();
         }
         var _loc2_:PMSkill = this._pmService.customData.pmSkillMap.getSkill(this._skillInfo.id);
         return _loc1_;
      }
      
      private function getNowLvTips() : String
      {
         var _loc1_:IMiraclePetDataService = ServiceContainer.getService(IMiraclePetDataService) as IMiraclePetDataService;
         var _loc2_:MiraclePetBreakData = _loc1_.getMiraclePetBreakDataByRaceId(this._miraclePetId);
         this._seriesIndex = _loc2_.breakSeriers.indexOf(this._miraclePetId);
         return "当前等级:" + seriesIndexToLvStr(this._seriesIndex) + "\n" + getPetSkillDec(this._miraclePetId,this._skillIndex);
      }
      
      private function getNextLvTips() : String
      {
         var _loc1_:IMiraclePetDataService = ServiceContainer.getService(IMiraclePetDataService) as IMiraclePetDataService;
         var _loc2_:MiraclePetBreakData = _loc1_.getMiraclePetBreakDataByRaceId(this._miraclePetId);
         this._seriesIndex = _loc2_.breakSeriers.indexOf(this._miraclePetId);
         var _loc3_:int = this._seriesIndex + 1;
         var _loc4_:int = int(_loc2_.breakSeriers[_loc3_]);
         return "下一等级:" + seriesIndexToLvStr(_loc3_) + "\n" + getPetSkillDec(_loc4_,this._skillIndex);
      }
      
      private function getMaxLvTips() : String
      {
         var _loc1_:IMiraclePetDataService = ServiceContainer.getService(IMiraclePetDataService) as IMiraclePetDataService;
         var _loc2_:MiraclePetBreakData = _loc1_.getMiraclePetBreakDataByRaceId(this._miraclePetId);
         var _loc3_:int = int(_loc2_.breakSeriers[_loc2_.breakSeriers.length - 1]);
         return "最高等级:LVMAX\n" + getPetSkillDec(_loc3_,this._skillIndex);
      }
      
      public function dispose() : void
      {
      }
   }
}

