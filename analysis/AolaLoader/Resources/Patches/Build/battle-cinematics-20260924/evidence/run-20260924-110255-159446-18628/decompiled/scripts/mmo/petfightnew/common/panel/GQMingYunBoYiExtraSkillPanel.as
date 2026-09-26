package mmo.petfightnew.common.panel
{
   import flash.display.MovieClip;
   import flash.text.TextField;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.pet.data.GQMingYunBoYiSkillParse;
   import mmo.interfaces.pet.data.IPetSkillMesService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.SkillInfo;
   import mmo.interfaces.pet.pm.data.custom.PMData;
   import mmo.interfaces.pet.pm.data.custom.PMSkill;
   import mmo.interfaces.pet.pm.data.custom.PMSkillTypes;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.manager.ServicePool;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol2699")]
   public class GQMingYunBoYiExtraSkillPanel extends MovieClip
   {
      
      public var mcskill_0:MovieClip;
      
      public var mcskill_1:MovieClip;
      
      public var mcskill_2:MovieClip;
      
      private var _originalSkill:PMSkill;
      
      private var _pbi:PetBriefInfo = null;
      
      private var _pmSvr:IPMService = ServicePool.instance.getService(IPMService);
      
      private var _pmData:PMData;
      
      private var _pskSvr:IPetSkillMesService = null;
      
      private var _skillInfo:SkillInfo;
      
      private var _skillList:Array = [];
      
      public function GQMingYunBoYiExtraSkillPanel(param1:SkillInfo)
      {
         super();
         this._pbi = FightData.instance.myInfo.operatingPlayer.myPets[0];
         this._originalSkill = this._pmSvr.customData.pmSkillMap.getSkill(param1.id);
         this._skillInfo = param1;
         this._pmData = this._pmSvr.getOperationPM(this._pbi.raceId).pmData;
         this._pskSvr = ServicePool.instance.getService(IPetSkillMesService);
         this.init();
      }
      
      private function init() : void
      {
         this.initSkillList();
         if(this._skillList.length > 1)
         {
            this.visible = true;
            this.refresh();
         }
         else
         {
            this.visible = false;
         }
      }
      
      public function setClickable(param1:Boolean) : void
      {
      }
      
      private function initSkillList() : void
      {
         var _loc1_:GQMingYunBoYiSkillParse = GQMingYunBoYiSkillParse.getGQMingYunBoYiSkillParse(this._pbi.raceId);
         this._skillList = [];
         if(PMSkillTypes.isGQKillBig(this._originalSkill.getSkillType()))
         {
            this._skillList = [this._originalSkill.skillId].concat(_loc1_.killBigSkillIds);
         }
         else
         {
            this._skillList = [this._originalSkill.skillId].concat(_loc1_.zhuanshuSkillIds);
         }
      }
      
      public function refresh() : void
      {
         var _loc2_:MovieClip = null;
         var _loc3_:PMSkill = null;
         var _loc4_:String = null;
         var _loc1_:int = 0;
         while(_loc1_ < this._skillList.length)
         {
            _loc2_ = this.getChildByName("mcskill_" + _loc1_) as MovieClip;
            if(_loc2_ != null)
            {
               _loc2_.visible = true;
               if(this._skillList[_loc1_] != -1)
               {
                  _loc3_ = this._pmSvr.customData.pmSkillMap.getSkill(this._skillList[_loc1_]);
                  if(_loc3_ == null)
                  {
                     _loc2_.gotoAndStop(3);
                     _loc2_.visible = false;
                  }
                  else
                  {
                     _loc2_.gotoAndStop(1);
                     (_loc2_.txtName as TextField).text = _loc3_.newCnName;
                     _loc4_ = _loc3_.newCnName + " 威力：" + this.getSkillPowerDesc(_loc3_.power);
                     TipsManager.getInstance().replaceComplexTips(_loc2_,_loc4_,_loc3_.clientDesc,100,-100,9);
                  }
               }
               else
               {
                  _loc2_.gotoAndStop(3);
               }
            }
            _loc1_++;
         }
      }
      
      private function getSkillPowerDesc(param1:int) : String
      {
         if(param1 > 0)
         {
            return param1.toString();
         }
         return "未知";
      }
   }
}

