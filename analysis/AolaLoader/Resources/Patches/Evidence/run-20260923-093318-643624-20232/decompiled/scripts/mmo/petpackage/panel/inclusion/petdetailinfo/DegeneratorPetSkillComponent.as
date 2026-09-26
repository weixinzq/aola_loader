package mmo.petpackage.panel.inclusion.petdetailinfo
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.SkillInfo;
   import mmo.interfaces.pet.pm.data.custom.PMSkill;
   import mmo.interfaces.pet.pm.data.custom.PMSkillTypes;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.petpackage.panel.inclusion.PetAttrIcon;
   import mmo.play.activity.helper.Panel_Helper;
   
   public class DegeneratorPetSkillComponent
   {
      
      private var _view:MovieClip = null;
      
      private var _pmService:IPMService;
      
      private var _petAttrIcon:PetAttrIcon;
      
      private var _skillInfo:SkillInfo = null;
      
      private var _pmSkill:PMSkill = null;
      
      public function DegeneratorPetSkillComponent(param1:MovieClip)
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
         var _loc2_:String = null;
         var _loc3_:MovieClip = null;
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         var _loc6_:String = null;
         var _loc7_:PMSkill = null;
         var _loc8_:PMSkill = null;
         if(param1 == null)
         {
            this._view.visible = false;
            return;
         }
         this._view.visible = true;
         this._skillInfo = param1;
         this._pmSkill = this._pmService.customData.pmSkillMap.getSkill(this._skillInfo.id);
         if(this._pmSkill.getSkillType() != PMSkillTypes.DEGENERATOR_LOCK_SKILL && this._pmSkill.getSkillType() != PMSkillTypes.DEGENERATOR_COMMON_SPIRIT_PO && this._pmSkill.getSkillType() != PMSkillTypes.DEGENERATOR_SUPER_SPIRIT_YU_PASSIVE && this._pmSkill.getSkillType() != PMSkillTypes.DEGENERATOR_SUPER_SPIRIT_BAO_PASSIVE && this._pmSkill.getSkillType() != PMSkillTypes.DEGENERATOR_SUPER_SPIRIT_ZHU_PASSIVE && this._pmSkill.getSkillType() != PMSkillTypes.DEGENERATOR_SUPER_SPIRIT_ZHAOHUAN_PASSIVE)
         {
            this._petAttrIcon.refresh(this._pmSkill.attributeType);
            Panel_Helper.setTextValue(this._view,"txtname",this._pmSkill.newCnName);
            _loc2_ = this._pmSkill.power < 0 ? "—" : this._pmSkill.power.toString();
            Panel_Helper.setTextValue(this._view,"txtpower",_loc2_);
            if(this._pmSkill.allPP <= 0)
            {
               _loc6_ = "--/--";
            }
            else
            {
               _loc6_ = param1.canUseTimes + "/" + this._pmSkill.allPP;
            }
            Panel_Helper.setTextValue(this._view,"txtpp",_loc6_);
            _loc3_ = this._view.mcskilltype;
            _loc4_ = 5;
            _loc5_ = int(this._pmSkill.getSkillType());
            switch(_loc5_)
            {
               case PMSkillTypes.DEGENERATOR_KILL_BIG:
                  _loc4_ = 1;
                  break;
               case PMSkillTypes.DEGENERATOR_PASSIVE_SKILL:
                  _loc4_ = 2;
                  break;
               case PMSkillTypes.DEGENERATOR_YU_KILL_BIG:
                  _loc4_ = 3;
                  break;
               case PMSkillTypes.DEGENERATOR_SHENQI_KILL_BIG:
                  _loc4_ = 4;
                  break;
               default:
                  _loc4_ = 5;
            }
            _loc3_.gotoAndStop(_loc4_);
            Panel_Helper.setTextValue(this._view,"txtskilllevel","Lv" + this._pmSkill.getSkillLevel());
            TipsManager.getInstance().replaceComplexTips(this._view,this.getSkillTipsTitle(),this.getSkillTipsContent(),0,9,-50);
         }
         else
         {
            _loc7_ = this._pmService.customData.pmSkillMap.getSkill(this._pmSkill.getMaxLevelSkillId());
            if(_loc7_.getLegendFiledEffectChange() > 0)
            {
               _loc8_ = this._pmService.customData.pmSkillMap.getSkill(_loc7_.getLegendFiledEffectChange());
            }
            else
            {
               _loc8_ = _loc7_;
            }
            (this._view.mcskilltype as MovieClip).gotoAndStop(_loc8_.getSkillType() - 5);
            TipsManager.getInstance().replaceComplexTips(this._view,this.getSkillTipsTitle(),this.getPoSkillTipsContent(),0,9,-50);
         }
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
         if(this._pmSkill.getSkillType() == PMSkillTypes.DEGENERATOR_COMMON_SPIRIT_PO || this._pmSkill.getSkillType() == PMSkillTypes.DEGENERATOR_SUPER_SPIRIT_YU_PASSIVE || this._pmSkill.getSkillType() == PMSkillTypes.DEGENERATOR_SUPER_SPIRIT_BAO_PASSIVE || this._pmSkill.getSkillType() == PMSkillTypes.DEGENERATOR_SUPER_SPIRIT_ZHU_PASSIVE || this._pmSkill.getSkillType() == PMSkillTypes.DEGENERATOR_SUPER_SPIRIT_ZHAOHUAN_PASSIVE)
         {
            return this._pmSkill.newCnName + " Lv." + (this._pmSkill.getSkillLevel() - 1) + "  " + this.getSkillAttackTypeDesc(this._pmSkill.attackType);
         }
         return this._pmSkill.newCnName + " Lv." + this._pmSkill.getSkillLevel() + "  " + this.getSkillAttackTypeDesc(this._pmSkill.attackType);
      }
      
      private function getPoSkillTipsContent() : String
      {
         var _loc2_:int = 0;
         var _loc3_:PMSkill = null;
         var _loc4_:int = 0;
         var _loc5_:PMSkill = null;
         var _loc1_:String = "";
         if(this._pmSkill.getSkillType() == PMSkillTypes.DEGENERATOR_LOCK_SKILL)
         {
            _loc1_ += this.getCurLevelSkillTipsContent() + this.getSplitLine();
            _loc2_ = int(this._pmSkill.getNextLevelSkillId());
            _loc3_ = this._pmService.customData.pmSkillMap.getSkill(_loc2_);
            _loc4_ = _loc3_.getLegendFiledEffectChange() > 0 ? int(_loc3_.getLegendFiledEffectChange()) : int(_loc3_.skillId);
            _loc5_ = this._pmService.customData.pmSkillMap.getSkill(_loc4_);
            _loc1_ += _loc5_.costSoulNum + "元气时升级为以下效果：\n" + "威力:" + _loc5_.power + "\n" + _loc5_.clientDesc;
         }
         else
         {
            _loc1_ += this.getCurLevelSkillTipsContent() + this.getSplitLine();
            _loc4_ = this._pmSkill.getLegendFiledEffectChange() > 0 ? int(this._pmSkill.getLegendFiledEffectChange()) : int(this._pmSkill.skillId);
            _loc5_ = this._pmService.customData.pmSkillMap.getSkill(_loc4_);
            _loc1_ += _loc5_.costSoulNum + "元气时升级为以下效果：\n" + "威力:" + _loc5_.power + "\n" + _loc5_.clientDesc;
         }
         return _loc1_;
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

