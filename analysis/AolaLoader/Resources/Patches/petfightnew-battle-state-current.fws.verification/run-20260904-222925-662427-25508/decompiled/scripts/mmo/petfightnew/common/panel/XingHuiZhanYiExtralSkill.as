package mmo.petfightnew.common.panel
{
   import flash.display.MovieClip;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.XingHuiZhanYiSkillParser;
   import mmo.interfaces.pet.pm.data.custom.PMSkill;
   import mmo.interfaces.pet.pm.data.custom.PMSkillTypes;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.petfightnew.common.manager.ServicePool;
   
   public class XingHuiZhanYiExtralSkill extends MovieClip
   {
      
      private static const maxEnery:int = 100;
      
      private var _pmSkill:PMSkill;
      
      private var pmService:IPMService = ServicePool.instance.getService(IPMService);
      
      private var _isBrust:Boolean;
      
      protected var _xingHuiZhanYiParser:XingHuiZhanYiSkillParser;
      
      private var _pbi:PetBriefInfo;
      
      private var _passiveSkillMc:MovieClip;
      
      public function XingHuiZhanYiExtralSkill()
      {
         super();
      }
      
      public function setData(param1:PetBriefInfo, param2:MovieClip, param3:int) : void
      {
         this._pmSkill = this.pmService.customData.pmSkillMap.getSkill(param3);
         var _loc4_:int = int(this._pmSkill.getSkillType());
         if(_loc4_ == PMSkillTypes.ZHANYI_BURST_PASSIVE)
         {
            this._isBrust = true;
         }
         else
         {
            if(_loc4_ != PMSkillTypes.ZHANYI_COMMON_PASSIVE)
            {
               return;
            }
            this._isBrust = false;
         }
         this._passiveSkillMc = param2;
         this._pbi = param1;
         this._xingHuiZhanYiParser = this._pbi.getXingHuiZhanYiSkillParser();
         if(this._isBrust)
         {
            this.burstHandle();
         }
         else
         {
            this.commonHandle();
         }
         var _loc5_:MovieClip = this._passiveSkillMc.getChildByName("mcIcon") as MovieClip;
         if(_loc5_)
         {
            TipsManager.getInstance().replaceComplexTips(_loc5_,this.getSkillTipsTitle(this._pmSkill),this.getSkillTipsContent(this._pmSkill),0,9,-50);
         }
      }
      
      private function commonHandle() : void
      {
         this._passiveSkillMc.gotoAndStop(1);
         var _loc1_:MovieClip = this._passiveSkillMc.getChildByName("mcPro") as MovieClip;
         if(_loc1_)
         {
            _loc1_.gotoAndStop(int(this._xingHuiZhanYiParser.energy() / XingHuiZhanYiExtralSkill.maxEnery * 10 + 1));
            TipsManager.getInstance().replaceTips(_loc1_,"战意能量：" + this._xingHuiZhanYiParser.energy() + "/" + XingHuiZhanYiExtralSkill.maxEnery);
         }
      }
      
      private function burstHandle() : void
      {
         this._passiveSkillMc.gotoAndStop(2);
         var _loc1_:MovieClip = this._passiveSkillMc.getChildByName("mcPro") as MovieClip;
         if(_loc1_)
         {
            _loc1_.gotoAndStop(int(this._xingHuiZhanYiParser.curRound() / this._xingHuiZhanYiParser.maxRound() * 10) + 1);
            TipsManager.getInstance().replaceTips(_loc1_,"当前已战意变身，技能、数值大大加强！");
         }
      }
      
      private function getSkillTipsTitle(param1:PMSkill) : String
      {
         return param1.newCnName + " Lv." + param1.getSkillLevel() + "  " + this.getSkillAttackTypeDesc(param1.attackType);
      }
      
      private function getSkillTipsContent(param1:PMSkill) : String
      {
         return "威力:" + param1.power + "\n" + param1.clientDesc;
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
   }
}

