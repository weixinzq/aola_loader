package mmo.petfightnew.common.fightcontroller
{
   import mmo.interfaces.IDispose;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.petfightnew.common.FightController;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.FightPanel;
   
   public class TerritoryRelive implements IDispose
   {
      
      private static var _instance:TerritoryRelive;
      
      private var fightPanel:FightPanel;
      
      private var _isMyPetInPMMList:Boolean = false;
      
      private var _pmSummonerArr:Array = [];
      
      public function TerritoryRelive()
      {
         super();
      }
      
      public static function get instance() : TerritoryRelive
      {
         if(_instance == null)
         {
            _instance = new TerritoryRelive();
         }
         return _instance;
      }
      
      public function init(param1:FightPanel) : void
      {
         this.fightPanel = param1;
      }
      
      public function relive(param1:Object) : void
      {
         this.handleDatas(param1);
         if(this._pmSummonerArr.length != 0)
         {
            SummonPetProcessor.instance.summonPet(this._pmSummonerArr);
            this._pmSummonerArr = [];
         }
         else
         {
            FightController.instance.startHandle();
         }
      }
      
      private function handleDatas(param1:Object) : void
      {
         var _loc4_:Object = null;
         var _loc5_:PlayerBattleInfo = null;
         var _loc2_:Array = param1.pmmList;
         var _loc3_:int = int(param1.reqSId);
         FightController.instance.desc = param1.desc;
         FightController.instance.pmmStatuses = [];
         this._isMyPetInPMMList = false;
         for each(_loc4_ in _loc2_)
         {
            _loc5_ = new PlayerBattleInfo();
            _loc5_.parseInfo(_loc4_);
            _loc5_ = FightData.instance.setLocaId(_loc5_);
            this.parseSummonerPMMDatas(_loc5_,_loc4_);
         }
      }
      
      private function parseSummonerPMMDatas(param1:PlayerBattleInfo, param2:Object) : void
      {
         var _loc3_:PlayerBattleInfo = FightData.instance.playerInfo[param1.slotId];
         if(_loc3_ == null)
         {
            FightData.instance.addPlayer(param1);
            _loc3_ = param1;
         }
         else
         {
            _loc3_.updateIdentityInfo(param2);
            (_loc3_.myPets[0] as PetBriefInfo).updateInfo(param1.myPets[0]);
         }
         this._pmSummonerArr.push(_loc3_);
      }
      
      public function dispose() : void
      {
         this.fightPanel = null;
         this._pmSummonerArr = [];
         _instance = null;
      }
   }
}

