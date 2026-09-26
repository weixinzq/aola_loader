package mmo.petfightnew.common.panel.skill.espskillpanel
{
   import flash.display.MovieClip;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.pet.XingHuiPetHelperUtil;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.interfaces.pet.data.XingHuiShenLingSkillParser;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.interfaces.pet.pm.data.custom.PMData;
   import mmo.interfaces.pet.pm.data.custom.PMSkill;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.interfaces.xinghui.XinghuiPetType;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.manager.ServicePool;
   import mmo.play.actthings.helper.ActComHelper;
   
   public class XH_ShenLingExtraPanel
   {
      
      private var _content:MovieClip;
      
      private var _petInfo:PetBriefInfo;
      
      private var pmService:IPMService = ServicePool.instance.getService(IPMService);
      
      private var _myPlayer:PlayerBattleInfo;
      
      public function XH_ShenLingExtraPanel(param1:MovieClip)
      {
         super();
         this._content = param1;
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.SHEN_LING_APPEAR_MYSIDE,this.appearHandle);
      }
      
      public function dispose() : void
      {
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.SHEN_LING_APPEAR_MYSIDE,this.appearHandle);
      }
      
      private function appearHandle(param1:PetFightEvent) : void
      {
         if(!this._petInfo)
         {
            return;
         }
         this.update(this._petInfo);
      }
      
      public function update(param1:PetBriefInfo) : *
      {
         var _loc8_:MovieClip = null;
         var _loc9_:int = 0;
         var _loc10_:PMSkill = null;
         if(!this._content)
         {
            return;
         }
         this._content.gotoAndStop(XinghuiPetType.getShenLingExtraSkillFrame(param1.raceId));
         this._petInfo = param1;
         ActComHelper.setMcFrame(this._content,"mcPro",1);
         var _loc2_:PMData = this.pmService.getOperationPM(this._petInfo.raceId).pmData;
         if(!XinghuiPetType.isShenLingPassive(_loc2_.getXinghuiType()))
         {
            this._content.visible = false;
            return;
         }
         var _loc3_:XingHuiShenLingSkillParser = this._petInfo.getXingHuiShenLingSkillParser();
         if(_loc3_.level == -1)
         {
            this._content.visible = false;
            return;
         }
         this._myPlayer = this.getMyInfo();
         if(!this._myPlayer)
         {
            this._content.visible = false;
            return;
         }
         if(!this.getCallerMaster(FightData.SHENG_LING_POS_WE) && !this.getCallerMaster(FightData.SHENG_LING_POS_ENEMY))
         {
            this._content.visible = false;
            return;
         }
         this._content.visible = true;
         ActComHelper.setMcFrame(this._content,"mcPro",_loc3_.level + 1);
         var _loc4_:String = _loc2_.getXinghuiExtraConfig();
         var _loc5_:String = XingHuiPetHelperUtil.getXingHuiExtraSkillConig(_loc4_,"神灵技能");
         var _loc6_:Array = _loc5_.split("=")[1].split("#");
         var _loc7_:int = 0;
         while(_loc7_ < _loc6_.length)
         {
            _loc8_ = this._content.getChildByName("mcSkill_" + _loc7_) as MovieClip;
            if(_loc8_)
            {
               _loc9_ = parseInt(_loc6_[_loc7_]);
               _loc10_ = this.pmService.customData.pmSkillMap.getSkill(_loc9_);
               TipsManager.getInstance().replaceComplexTips(_loc8_,this.getSkillTipsTitle(_loc10_),this.getSkillTipsContent(_loc10_),0,9,-50);
            }
            _loc7_++;
         }
      }
      
      private function getCallerMaster(param1:int) : Boolean
      {
         var _loc2_:PlayerBattleInfo = FightData.instance.getPlayerInfoBySlotId(param1);
         if(!_loc2_)
         {
            return false;
         }
         return _loc2_.callerMasterId == this._myPlayer.PMMasterId && _loc2_.maidservantMsterSlotId == this._myPlayer.slotId;
      }
      
      private function getMyInfo() : PlayerBattleInfo
      {
         return FightData.instance.myInfo.operatingPlayer;
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

