package mmo.petpackage.panel.inclusion.petdetailinfo
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.SkillInfo;
   import mmo.interfaces.pet.pm.data.custom.PMLegendBigSkillTypes;
   import mmo.interfaces.pet.pm.data.custom.PMSkill;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.petpackage.panel.inclusion.PetAttrIcon;
   import mmo.play.activity.helper.Panel_Helper;
   
   public class LegendPetSkillComponent
   {
      
      private var _view:MovieClip = null;
      
      private var _pmService:IPMService;
      
      private var _petAttrIcon:PetAttrIcon;
      
      private var _skillInfo:SkillInfo = null;
      
      private var _pmSkill:PMSkill = null;
      
      public function LegendPetSkillComponent(param1:MovieClip)
      {
         super();
         this._view = param1;
         this.init();
      }
      
      private function init() : void
      {
         this._pmService = ServiceContainer.getService(IPMService) as IPMService;
         this._petAttrIcon = new PetAttrIcon();
         var _loc1_:Sprite = this._view.getChildByName("attrcontainer") as Sprite;
         _loc1_.addChild(this._petAttrIcon.view);
      }
      
      public function refresh(param1:SkillInfo) : void
      {
         var _loc4_:String = null;
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         if(param1 == null)
         {
            this._view.visible = false;
            return;
         }
         this._view.visible = true;
         this._skillInfo = param1;
         this._pmSkill = this._pmService.customData.pmSkillMap.getSkill(this._skillInfo.id);
         this._petAttrIcon.refresh(this._pmSkill.attributeType);
         Panel_Helper.setTextValue(this._view,"txtname",this._pmSkill.newCnName);
         var _loc2_:String = this._pmSkill.power < 0 ? "—" : this._pmSkill.power.toString();
         Panel_Helper.setTextValue(this._view,"txtpower",_loc2_);
         if(this._pmSkill.allPP <= 0)
         {
            _loc4_ = "--/--";
         }
         else
         {
            _loc4_ = param1.canUseTimes + "/" + this._pmSkill.allPP;
         }
         Panel_Helper.setTextValue(this._view,"txtpp",_loc4_);
         var _loc3_:MovieClip = this._view.mcskilltype;
         if(this._pmSkill.isLegendBigSkill())
         {
            _loc5_ = int(this._pmSkill.getLegendBigSkillType());
            _loc6_ = 1;
            switch(_loc5_)
            {
               case PMLegendBigSkillTypes.LEGEND_KILL_BIG:
                  _loc6_ = 1;
                  break;
               case PMLegendBigSkillTypes.LEGEND_FIELD_BIG:
                  _loc6_ = 2;
                  break;
               case PMLegendBigSkillTypes.LEGEND_TOTEM_BIG:
                  _loc6_ = 3;
            }
            _loc3_.gotoAndStop(_loc6_);
         }
         else if(this._pmSkill.isPassiveSkill)
         {
            _loc3_.gotoAndStop(4);
         }
         else
         {
            _loc3_.gotoAndStop(5);
         }
         Panel_Helper.setTextValue(this._view,"txtskilllevel","Lv" + this._pmSkill.getSkillLevel());
         TipsManager.getInstance().replaceComplexTips(this._view,this.getSkillTipsTitle(),this.getSkillTipsContent(),0,9,-50);
      }
      
      private function getSkillAttackTypeDesc(param1:int) : String
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
      
      private function getSkillTipsTitle() : String
      {
         return this._pmSkill.newCnName + " Lv." + this._pmSkill.getSkillLevel() + "  " + this.getSkillAttackTypeDesc(this._pmSkill.attackType);
      }
      
      private function getSkillTipsContent() : String
      {
         if(this._pmSkill.isMaxLevelSkill())
         {
            return this.getCurLevelSkillTipsContent() + this.getSplitLine() + "当前已经是最高等级了！";
         }
         return this.getCurLevelSkillTipsContent() + this.getSplitLine() + this.getNextLevelSkillTipsContent() + this.getSplitLine() + this.getMaxLevelSkillTipsContent();
      }
      
      private function getSplitLine() : String
      {
         return "\n-------\n";
      }
      
      private function getCurLevelSkillTipsContent() : String
      {
         return "威力:" + this._pmSkill.power + "\n" + this._pmSkill.clientDesc;
      }
      
      private function getNextLevelSkillTipsContent() : String
      {
         var _loc1_:int = int(this._pmSkill.getNextLevelSkillId());
         var _loc2_:PMSkill = this._pmService.customData.pmSkillMap.getSkill(_loc1_);
         return "下一等级:Lv." + _loc2_.getSkillLevel() + "\n" + "威力:" + _loc2_.power + "\n" + _loc2_.clientDesc;
      }
      
      private function getMaxLevelSkillTipsContent() : String
      {
         var _loc1_:int = int(this._pmSkill.getMaxLevelSkillId());
         var _loc2_:PMSkill = this._pmService.customData.pmSkillMap.getSkill(_loc1_);
         return "最高等级:Lv." + _loc2_.getSkillLevel() + "\n" + "威力:" + _loc2_.power + "\n" + _loc2_.clientDesc;
      }
      
      public function dispose() : void
      {
         this._petAttrIcon = null;
         this._pmSkill = null;
         this._skillInfo = null;
      }
   }
}

