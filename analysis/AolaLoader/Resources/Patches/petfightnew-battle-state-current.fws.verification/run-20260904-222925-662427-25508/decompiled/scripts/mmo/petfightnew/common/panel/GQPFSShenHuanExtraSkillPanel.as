package mmo.petfightnew.common.panel
{
   import flash.display.MovieClip;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.pet.data.IPetSkillMesService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.SkillInfo;
   import mmo.interfaces.pet.peticon.PetIconType;
   import mmo.interfaces.pet.pm.data.custom.PMData;
   import mmo.interfaces.pet.pm.data.custom.PMSkill;
   import mmo.interfaces.pet.pm.data.custom.PMSkillTypes;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.fightcontroller.UseBigSkillHandler;
   import mmo.petfightnew.common.manager.ServicePool;
   import mmo.play.activity.peticon.PetIconHandler;
   import mmo.play.actthings.helper.ActComHelper;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol2781")]
   public class GQPFSShenHuanExtraSkillPanel extends MovieClip
   {
      
      public var mcskill_0:MovieClip;
      
      public var mcskill_1:MovieClip;
      
      public var mcskill_2:MovieClip;
      
      private var _originalSkill:PMSkill;
      
      private var _pbi:PetBriefInfo = null;
      
      private var _pmSvr:IPMService = ServicePool.instance.getService(IPMService);
      
      private var _pmData:PMData;
      
      private var _pskSvr:IPetSkillMesService = null;
      
      private var _qiyueRaceIds:Array = [];
      
      private var _qiyueskillIds:Array = [];
      
      private var _changeViewBtnEnabled:Boolean = true;
      
      private var _skillInfo:SkillInfo;
      
      private var _petIconHandlers:Array = [];
      
      public function GQPFSShenHuanExtraSkillPanel(param1:SkillInfo)
      {
         super();
         this._originalSkill = this._pmSvr.customData.pmSkillMap.getSkill(param1.id);
         this._skillInfo = param1;
         this.init();
      }
      
      private function init() : void
      {
         this._pbi = FightData.instance.myInfo.operatingPlayer.myPets[0];
         this._pmData = this._pmSvr.getOperationPM(this._pbi.raceId).pmData;
         this._pskSvr = ServicePool.instance.getService(IPetSkillMesService);
         this.initRaceAndSkillList();
         if(this._qiyueskillIds.length > 0)
         {
            this.visible = true;
            this.gotoAndStop(this._qiyueskillIds.length);
            this.addEventListener(MouseEvent.CLICK,this.onClick);
            this.refresh();
         }
         else
         {
            this.visible = false;
         }
      }
      
      public function setClickable(param1:Boolean) : void
      {
         this._changeViewBtnEnabled = param1;
      }
      
      private function initRaceAndSkillList() : void
      {
         var _loc2_:PetBriefInfo = null;
         var _loc3_:int = 0;
         var _loc4_:PMSkill = null;
         this._qiyueRaceIds = [];
         this._qiyueskillIds = [];
         var _loc1_:int = 1;
         while(_loc1_ < 3)
         {
            if(_loc1_ < FightData.instance.myInfo.operatingPlayer.myPets.length)
            {
               _loc2_ = FightData.instance.myInfo.operatingPlayer.myPets[_loc1_];
               _loc3_ = 0;
               while(_loc3_ < _loc2_.skills.length)
               {
                  _loc4_ = this._pmSvr.customData.pmSkillMap.getSkill(_loc2_.skills[_loc3_].id);
                  if(Boolean(PMSkillTypes.isGQCommonSpiritSkill(_loc4_.getSkillType())) && Boolean(PMSkillTypes.isGQCommonSpiritSkill(this._originalSkill.getSkillType())))
                  {
                     if(_loc4_.costSoulNum == this._originalSkill.costSoulNum || _loc4_.costSoulNum > 1 && this._originalSkill.costSoulNum > 1)
                     {
                        this._qiyueskillIds.push(_loc4_.skillId);
                        this._qiyueRaceIds.push(_loc2_.raceId);
                        break;
                     }
                  }
                  else
                  {
                     if(Boolean(PMSkillTypes.isGQCommonSkill(_loc4_.getSkillType())) && Boolean(PMSkillTypes.isGQCommonSkill(this._originalSkill.getSkillType())))
                     {
                        this._qiyueskillIds.push(_loc4_.skillId);
                        this._qiyueRaceIds.push(_loc2_.raceId);
                        break;
                     }
                     if(Boolean(PMSkillTypes.isGQKillBig(_loc4_.getSkillType())) && Boolean(PMSkillTypes.isGQKillBig(this._originalSkill.getSkillType())))
                     {
                        this._qiyueskillIds.push(_loc4_.skillId);
                        this._qiyueRaceIds.push(_loc2_.raceId);
                        break;
                     }
                  }
                  _loc3_++;
               }
            }
            _loc1_++;
         }
      }
      
      public function refresh() : void
      {
         var _loc2_:MovieClip = null;
         var _loc3_:MovieClip = null;
         var _loc4_:PetIconHandler = null;
         var _loc5_:PMSkill = null;
         var _loc6_:String = null;
         var _loc7_:String = null;
         var _loc1_:int = 0;
         for(; _loc1_ < this._qiyueskillIds.length; _loc1_++)
         {
            _loc2_ = this.getChildByName("mcskill_" + _loc1_) as MovieClip;
            if(_loc2_ != null)
            {
               _loc2_.visible = true;
               if(this._qiyueskillIds[_loc1_] != -1)
               {
                  _loc5_ = this._pmSvr.customData.pmSkillMap.getSkill(this._qiyueskillIds[_loc1_]);
                  if(_loc5_ == null)
                  {
                     _loc2_.gotoAndStop(3);
                     _loc2_.visible = false;
                     continue;
                  }
                  if(Boolean(PMSkillTypes.isGQCommonSpiritSkill(_loc5_.getSkillType())) && this._pbi.curGQSoulNum < _loc5_.costSoulNum || _loc5_.getSkillType() == PMSkillTypes.GQ_COMMON_SKILL && this._skillInfo.canUseTimes <= 0 || Boolean(PMSkillTypes.isGQKillBig(_loc5_.getSkillType())) && this._pbi.curGQSoulNum < _loc5_.costSoulNum)
                  {
                     _loc2_.gotoAndStop(2);
                  }
                  else
                  {
                     _loc2_.gotoAndStop(1);
                  }
                  (_loc2_.txtName as TextField).text = _loc5_.newCnName;
                  _loc6_ = _loc5_.newCnName + " 威力：" + this.getSkillPowerDesc(_loc5_.power);
                  TipsManager.getInstance().replaceComplexTips(_loc2_,_loc6_,_loc5_.clientDesc,100,-100,9);
               }
               else
               {
                  _loc2_.gotoAndStop(3);
               }
               _loc3_ = _loc2_.getChildByName("mcCost") as MovieClip;
               if(Boolean(PMSkillTypes.isGQCommonSpiritSkill(_loc5_.getSkillType())) || Boolean(PMSkillTypes.isGQKillBig(_loc5_.getSkillType())))
               {
                  _loc3_.gotoAndStop(1);
                  ActComHelper.setMcFrame(_loc3_,"mcGQSoulNum",_loc5_.costSoulNum);
               }
               else
               {
                  _loc3_.gotoAndStop(2);
                  if(_loc5_.allPP <= 0)
                  {
                     _loc7_ = "--/--";
                  }
                  else
                  {
                     _loc7_ = this._skillInfo.canUseTimes + "/" + _loc5_.allPP;
                  }
                  ActComHelper.setTxtValue(_loc3_,"txtPP","PP:" + _loc7_);
               }
               if(this._petIconHandlers[_loc1_] == null)
               {
                  _loc4_ = new PetIconHandler(ActComHelper.getChildNode(_loc2_,"mcPetHead") as MovieClip,false,true);
                  this._petIconHandlers[_loc1_] = _loc4_;
               }
               _loc4_ = this._petIconHandlers[_loc1_];
               _loc4_.setIcon(this._qiyueRaceIds[_loc1_],PetIconType.FIGHT);
            }
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
            param1.stopImmediatePropagation();
            _loc2_ = parseInt(param1.target.parent.name.split("_")[1]);
            _loc3_ = int(this._qiyueskillIds[_loc2_]);
            _loc4_ = this._pmSvr.customData.pmSkillMap.getSkill(_loc3_);
            _loc5_ = int(_loc4_.getSkillType());
            if(UseBigSkillHandler.instance.isHandling() && !UseBigSkillHandler.instance.isUsingSkill(_loc5_,_loc3_))
            {
               UseBigSkillHandler.instance.cancelUse();
            }
            UseBigSkillHandler.instance.handleUse(this._pbi,100000,_loc5_,this.getRealIndex(_loc2_));
         }
      }
      
      private function getRealIndex(param1:int) : int
      {
         var _loc3_:int = 0;
         var _loc2_:PMSkill = this._pmSvr.customData.pmSkillMap.getSkill(this._qiyueskillIds[param1]);
         if(PMSkillTypes.isGQCommonSkill(_loc2_.getSkillType()))
         {
            _loc3_ = param1;
         }
         else if(PMSkillTypes.isGQCommonSpiritSkill(_loc2_.getSkillType()))
         {
            if(_loc2_.costSoulNum == 1)
            {
               _loc3_ = 2 + param1;
            }
            else
            {
               _loc3_ = 4 + param1;
            }
         }
         else
         {
            _loc3_ = 6 + param1;
         }
         return _loc3_;
      }
   }
}

