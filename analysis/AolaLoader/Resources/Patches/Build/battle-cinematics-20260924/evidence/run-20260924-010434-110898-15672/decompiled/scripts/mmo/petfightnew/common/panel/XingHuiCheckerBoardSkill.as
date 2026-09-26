package mmo.petfightnew.common.panel
{
   import flash.display.MovieClip;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.SkillInfo;
   import mmo.interfaces.pet.data.XHCheckerBoardSkillParse;
   import mmo.interfaces.pet.pm.data.custom.PMSkill;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.interfaces.xinghui.XinghuiPetType;
   import mmo.petfightnew.common.manager.ServicePool;
   
   public class XingHuiCheckerBoardSkill extends MovieClip
   {
      
      private var _pbi:PetBriefInfo;
      
      private var _skillDataAry:Array;
      
      private var _passiveSkillMc:MovieClip;
      
      private const boxNum:int = 5;
      
      private var pmService:IPMService = ServicePool.instance.getService(IPMService);
      
      public function XingHuiCheckerBoardSkill()
      {
         super();
      }
      
      public function setData(param1:PetBriefInfo, param2:MovieClip) : void
      {
         this._pbi = param1;
         this._passiveSkillMc = param2;
         this.parseSkill();
         this.updateView();
      }
      
      private function parseSkill() : void
      {
         var _loc2_:SkillInfo = null;
         var _loc4_:Array = null;
         var _loc5_:Object = null;
         this._skillDataAry = new Array();
         var _loc1_:Array = this._pbi.skills.concat();
         var _loc3_:int = int(_loc1_.length - 1);
         while(_loc3_ >= 0)
         {
            _loc2_ = _loc1_[_loc3_];
            _loc4_ = XHCheckerBoardSkillParse.getSkillType(this._pbi.raceId,_loc2_.id);
            if(!(_loc4_[0] == -1 || _loc4_[1] == XHCheckerBoardSkillParse.TYPE_BIG))
            {
               _loc5_ = {};
               _loc5_.skillId = _loc2_.id;
               _loc5_.tree = _loc4_[0];
               _loc5_.type = _loc4_[1];
               this._skillDataAry.push(_loc5_);
            }
            _loc3_--;
         }
      }
      
      private function updateView() : void
      {
         var _loc2_:MovieClip = null;
         var _loc5_:Object = null;
         var _loc6_:int = 0;
         var _loc7_:PMSkill = null;
         var _loc1_:int = 0;
         var _loc3_:Object = XinghuiPetType.getCheckerBoardByRaceId(this._pbi.raceId);
         var _loc4_:int = _loc3_ ? int(_loc3_.exSkillFrame) : 1;
         this._passiveSkillMc.gotoAndStop(_loc4_);
         _loc1_ = 0;
         while(_loc1_ < this.boxNum)
         {
            _loc2_ = this._passiveSkillMc.getChildByName("mcBox_" + _loc1_) as MovieClip;
            _loc2_.visible = false;
            _loc1_++;
         }
         _loc1_ = 0;
         while(_loc1_ < this._skillDataAry.length)
         {
            _loc5_ = this._skillDataAry[_loc1_];
            _loc2_ = this._passiveSkillMc.getChildByName("mcBox_" + _loc1_) as MovieClip;
            _loc2_.visible = true;
            _loc2_.gotoAndStop(_loc5_.tree + 1);
            _loc6_ = int(_loc5_.skillId);
            _loc7_ = this.pmService.customData.pmSkillMap.getSkill(_loc6_);
            TipsManager.getInstance().replaceComplexTips(_loc2_,this.getSkillTipsTitle(_loc7_),this.getSkillTipsContent(_loc7_),0,9,-50);
            _loc1_++;
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

