package mmo.petfightnew.common.panel
{
   import flash.display.MovieClip;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.interfaces.pet.data.IPetSkillMesService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.pm.data.custom.PMData;
   import mmo.interfaces.pet.pm.data.custom.PMSkill;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.fightcontroller.UseBigSkillHandler;
   import mmo.petfightnew.common.manager.ServicePool;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol4036")]
   public class DegeneratorZhaohuanBigKillPanel extends MovieClip
   {
      
      public var mcpet_0:MovieClip;
      
      public var mcpet_1:MovieClip;
      
      public var mcpet_2:MovieClip;
      
      public var mcpet_3:MovieClip;
      
      public var mcpet_4:MovieClip;
      
      public var mcpet_5:MovieClip;
      
      public var mcpet_6:MovieClip;
      
      private var _pbi:PetBriefInfo = null;
      
      private var _degeneratorBigSkill:PMSkill = null;
      
      private var _pmSvr:IPMService = ServicePool.instance.getService(IPMService);
      
      private var _pmData:PMData;
      
      private var _pskSvr:IPetSkillMesService = null;
      
      private var _summonRaceList:Array = [];
      
      private var _changeViewBtnEnabled:Boolean = true;
      
      public function DegeneratorZhaohuanBigKillPanel(param1:int)
      {
         super();
         this._degeneratorBigSkill = this._pmSvr.customData.pmSkillMap.getSkill(param1);
         this.init();
      }
      
      private function init() : void
      {
         this._pbi = FightData.instance.myInfo.operatingPlayer.myPets[0];
         this._pmData = this._pmSvr.getOperationPM(this._pbi.raceId).pmData;
         this._pskSvr = ServicePool.instance.getService(IPetSkillMesService);
         this._summonRaceList = this._pmData.summonPetArr;
         this.gotoAndStop(this._summonRaceList.length - 2);
         this.addEventListener(MouseEvent.CLICK,this.onClick);
         this.refresh();
      }
      
      public function setClickable(param1:Boolean) : void
      {
         this._changeViewBtnEnabled = param1;
      }
      
      public function refresh() : void
      {
         var _loc2_:MovieClip = null;
         this._pbi = FightData.instance.myInfo.operatingPlayer.myPets[0];
         var _loc1_:int = 0;
         while(_loc1_ < this._summonRaceList.length)
         {
            _loc2_ = this.getChildByName("mcpet_" + _loc1_) as MovieClip;
            if(this._summonRaceList[_loc1_] != -1)
            {
               if(this._pbi.getZhaohuanArr().length == 0 || this._pbi.getZhaohuanArr()[_loc1_] == 0)
               {
                  _loc2_.gotoAndStop(3);
               }
               else if(this._pbi.curDegeneratorSoulNum < this._degeneratorBigSkill.costSoulNum)
               {
                  _loc2_.gotoAndStop(2);
               }
               else
               {
                  _loc2_.gotoAndStop(1);
               }
               (_loc2_.txtName as TextField).text = this._pmSvr.getOperationPM(this._summonRaceList[_loc1_]).pmData.pmName.split("（")[0];
            }
            else
            {
               _loc2_.gotoAndStop(3);
            }
            _loc1_++;
         }
      }
      
      private function onClick(param1:MouseEvent) : void
      {
         var _loc2_:int = 0;
         var _loc3_:int = 0;
         if(!this._changeViewBtnEnabled)
         {
            return;
         }
         if(param1.target.name == "btnpet")
         {
            _loc2_ = parseInt(param1.target.parent.name.split("_")[1]);
            _loc3_ = int(this._degeneratorBigSkill.getSkillType());
            if(UseBigSkillHandler.instance.isHandling() && !UseBigSkillHandler.instance.isUsingSkill(_loc3_,this._degeneratorBigSkill.skillId))
            {
               UseBigSkillHandler.instance.cancelUse();
            }
            UseBigSkillHandler.instance.handleUse(this._pbi,this._degeneratorBigSkill.skillId,_loc3_,_loc2_);
         }
      }
   }
}

