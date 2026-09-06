package mmo.petfightnew.common.panel.pet
{
   import flash.display.MovieClip;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.interfaces.pet.data.XingHuiShenLingSkillParser;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.interfaces.xinghui.XinghuiPetType;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.manager.ServicePool;
   import mmo.play.actthings.helper.ActComHelper;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol2764")]
   public class ShenLingPetInfoMC extends PetInfoMCBase
   {
      
      public var mcHp_0:MovieClip;
      
      public var mcHp_1:MovieClip;
      
      public var mcHp_2:MovieClip;
      
      public var mcKaOuNum:MovieClip;
      
      public var mcLvBox:MovieClip;
      
      private var _pmService:IPMService = ServicePool.instance.getService(IPMService);
      
      private var _pbi:PetBriefInfo;
      
      private const _maxHp:int = 3;
      
      private var _lastLevel:int = -1;
      
      public function ShenLingPetInfoMC()
      {
         super();
         this.init();
         CommonEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.SHEN_LING_APPEAR_MYSIDE,{}));
      }
      
      private function init() : void
      {
      }
      
      override public function setPet(param1:PlayerBattleInfo) : void
      {
         var _loc9_:MovieClip = null;
         var _loc10_:XingHuiShenLingSkillParser = null;
         var _loc2_:PetBriefInfo = param1.myPets[0];
         this._pbi = _loc2_;
         var _loc3_:XingHuiShenLingSkillParser = _loc2_.getXingHuiShenLingSkillParser();
         var _loc4_:Object = XinghuiPetType.getShenLingGuard_Object(this._pbi.raceId);
         var _loc5_:MovieClip = this.getChildByName("mcLvBox") as MovieClip;
         _loc5_.gotoAndStop(_loc4_.lvFrame + 1);
         var _loc6_:MovieClip = _loc5_.getChildByName("mcLv") as MovieClip;
         _loc6_.gotoAndStop(_loc3_.level + 1);
         var _loc7_:int = 0;
         while(_loc7_ < this._maxHp)
         {
            _loc9_ = this.getChildByName("mcHp_" + _loc7_) as MovieClip;
            if(_loc9_)
            {
               _loc9_.visible = _loc3_.hp > _loc7_;
               if(Boolean(_loc4_) && Boolean(_loc4_.hpFrame))
               {
                  _loc9_.gotoAndStop(_loc4_.hpFrame);
               }
               else
               {
                  _loc9_.gotoAndStop(1);
               }
            }
            _loc7_++;
         }
         if(this._lastLevel > -1 && _loc3_.level >= -1)
         {
            if(this._lastLevel > _loc3_.level)
            {
               CommonEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.SHEN_LING_LEVEL_CHANGE,{
                  "pid":this._pbi.id,
                  "isUp":false,
                  "level":_loc3_.level,
                  "locaId":param1.locaId
               }));
            }
            else if(this._lastLevel < _loc3_.level)
            {
               CommonEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.SHEN_LING_LEVEL_CHANGE,{
                  "pid":this._pbi.id,
                  "isUp":true,
                  "level":_loc3_.level,
                  "locaId":param1.locaId
               }));
            }
         }
         this._lastLevel = _loc3_.level;
         var _loc8_:MovieClip = this.getChildByName("mcKaOuNum") as MovieClip;
         if(_loc8_)
         {
            _loc10_ = this.getMsterPlayerSkillParser(param1);
            if(!_loc10_ || _loc10_.kaAoSiDecTime < 0)
            {
               _loc8_.visible = false;
               ActComHelper.setMcNum(_loc8_,"mcnum",0);
            }
            else
            {
               ActComHelper.setMcNum(_loc8_,"mcnum",_loc10_.kaAoSiDecTime);
               _loc8_.visible = true;
            }
         }
      }
      
      private function getMsterPlayerSkillParser(param1:PlayerBattleInfo) : XingHuiShenLingSkillParser
      {
         var _loc2_:PlayerBattleInfo = null;
         var _loc3_:PetBriefInfo = null;
         for each(_loc2_ in FightData.instance.playerInfo)
         {
            if(param1.callerMasterId == _loc2_.PMMasterId)
            {
               _loc3_ = _loc2_.myPets[0];
               return _loc3_.getXingHuiShenLingSkillParser();
            }
         }
         return null;
      }
      
      override public function dispose() : void
      {
         this._pmService = null;
      }
   }
}

