package mmo.petfightnew.common.panel
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.pet.data.IPetSkillMesService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.pm.data.custom.PMData;
   import mmo.interfaces.pet.pm.data.custom.PMSkill;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.fightcontroller.UseBigSkillHandler;
   import mmo.petfightnew.common.manager.ServicePool;
   import mmo.petfightnew.common.util.DegeneratorPetHelper;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol4095")]
   public class DegeneratorYulingBigKillPanel extends MovieClip
   {
      
      public var mcskill_0:MovieClip;
      
      public var mcskill_1:MovieClip;
      
      public var mcskill_2:MovieClip;
      
      public var mcskill_3:MovieClip;
      
      public var mcskill_4:MovieClip;
      
      public var mcskill_5:MovieClip;
      
      public var mcskill_6:MovieClip;
      
      private var _pbi:PetBriefInfo = null;
      
      private var _degeneratorBigSkill:PMSkill = null;
      
      private var _pmSvr:IPMService;
      
      private var _pmData:PMData;
      
      private var _pskSvr:IPetSkillMesService = null;
      
      private var _skillList:Array = [];
      
      private var _changeViewBtnEnabled:Boolean = true;
      
      public function DegeneratorYulingBigKillPanel()
      {
         super();
         this.init();
      }
      
      private function init() : void
      {
         this._pbi = FightData.instance.myInfo.operatingPlayer.myPets[0];
         this._degeneratorBigSkill = DegeneratorPetHelper.getDegeneratorPetBigSkill(this._pbi);
         this._pmSvr = ServicePool.instance.getService(IPMService);
         this._pmData = this._pmSvr.getOperationPM(this._pbi.raceId).pmData;
         this._pskSvr = ServicePool.instance.getService(IPetSkillMesService);
         this.initSkillList();
         this.gotoAndStop(this._skillList.length - 2);
         this.addEventListener(MouseEvent.CLICK,this.onClick);
         this.refresh();
      }
      
      public function setClickable(param1:Boolean) : void
      {
         this._changeViewBtnEnabled = param1;
      }
      
      private function initSkillList() : void
      {
         var _loc1_:Object = null;
         var _loc2_:int = 0;
         this._skillList = [];
         for each(_loc1_ in this._pmData.beYuObjetArr)
         {
            _loc2_ = -1;
            if(_loc1_["skillId"] != -1)
            {
               _loc2_ = int(this._pmSvr.customData.pmSkillMap.getSkill(_loc1_["skillId"]).skillSerials[this._degeneratorBigSkill.getSkillLevel() - 1]);
            }
            this._skillList.push(_loc2_);
         }
      }
      
      public function refresh() : void
      {
         var _loc2_:MovieClip = null;
         var _loc3_:PMSkill = null;
         var _loc4_:String = null;
         var _loc5_:int = 0;
         var _loc6_:Sprite = null;
         this._pbi = FightData.instance.myInfo.operatingPlayer.myPets[0];
         var _loc1_:int = 0;
         while(_loc1_ < this._skillList.length)
         {
            _loc2_ = this.getChildByName("mcskill_" + _loc1_) as MovieClip;
            if(this._skillList[_loc1_] != -1)
            {
               _loc3_ = this._pmSvr.customData.pmSkillMap.getSkill(this._skillList[_loc1_]);
               if((this._pbi.getQilingArr().length == 0 || this._pbi.getQilingArr()[_loc1_] == -1) && _loc1_ != 0)
               {
                  _loc2_.gotoAndStop(3);
               }
               else if(this._pbi.curDegeneratorSoulNum < _loc3_.costSoulNum)
               {
                  _loc2_.gotoAndStop(2);
               }
               else
               {
                  _loc2_.gotoAndStop(1);
               }
               (_loc2_.txtName as TextField).text = _loc3_.newCnName;
               _loc4_ = _loc3_.newCnName + " 威力：" + this.getSkillPowerDesc(_loc3_.power);
               TipsManager.getInstance().replaceComplexTips(_loc2_,_loc4_,_loc3_.clientDesc,100,-100,9);
               _loc5_ = int(this._pskSvr.getPetSkillMes(this._skillList[_loc1_]).attribute);
               _loc6_ = this._pskSvr.getSkillAttributeIcon(_loc5_);
               _loc6_.x = _loc2_.iconHd.x;
               _loc6_.y = _loc2_.iconHd.y;
               _loc2_.addChildAt(_loc6_,_loc2_.getChildIndex(_loc2_.iconHd) + 1);
               TipsManager.getInstance().addTips(_loc6_,this._pskSvr.getPetAttributeTipsByattributeId(_loc5_));
            }
            else
            {
               _loc2_.gotoAndStop(3);
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
      
      private function onClick(param1:MouseEvent) : void
      {
         var _loc2_:int = 0;
         var _loc3_:int = 0;
         var _loc4_:PMSkill = null;
         var _loc5_:int = 0;
         if(!this._changeViewBtnEnabled)
         {
            return;
         }
         if(param1.target.name == "btnskill")
         {
            _loc2_ = parseInt(param1.target.parent.name.split("_")[1]);
            _loc3_ = int(this._skillList[_loc2_]);
            _loc4_ = this._pmSvr.customData.pmSkillMap.getSkill(_loc3_);
            _loc5_ = int(_loc4_.getSkillType());
            if(UseBigSkillHandler.instance.isHandling() && !UseBigSkillHandler.instance.isUsingSkill(_loc5_,_loc3_))
            {
               UseBigSkillHandler.instance.cancelUse();
            }
            UseBigSkillHandler.instance.handleUse(this._pbi,_loc3_,_loc5_);
         }
      }
   }
}

