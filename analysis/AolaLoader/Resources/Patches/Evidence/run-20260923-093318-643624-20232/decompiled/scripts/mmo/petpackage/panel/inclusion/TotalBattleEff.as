package mmo.petpackage.panel.inclusion
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.IPetBattleEffDataService;
   import mmo.interfaces.pet.data.IPetDataService;
   import mmo.interfaces.pet.data.PetDataServiceEvent;
   import mmo.interfaces.petcorps.IPetCorpsService;
   import mmo.interfaces.summoner.ISummonerDataService;
   import mmo.util.component.artnumber.ArtNumberManager;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol1063")]
   public class TotalBattleEff extends Sprite
   {
      
      public var max_0:MovieClip;
      
      public var max_1:MovieClip;
      
      public var max_2:MovieClip;
      
      public var max_3:MovieClip;
      
      public var max_4:MovieClip;
      
      public var max_5:MovieClip;
      
      public var max_6:MovieClip;
      
      public var mcHighestEff:MovieClip;
      
      public var mcPackageEff:MovieClip;
      
      public var num_0:MovieClip;
      
      public var num_1:MovieClip;
      
      public var num_2:MovieClip;
      
      public var num_3:MovieClip;
      
      public var num_4:MovieClip;
      
      public var num_5:MovieClip;
      
      private var pbeds:IPetBattleEffDataService;
      
      private var petDataService:IPetDataService;
      
      private var petCorpsService:IPetCorpsService;
      
      private var summonerDataService:ISummonerDataService;
      
      private var _totalEff:int = 0;
      
      public function TotalBattleEff()
      {
         super();
      }
      
      public function init() : void
      {
         this.pbeds = ServiceContainer.getService(IPetBattleEffDataService) as IPetBattleEffDataService;
         this.petDataService = ServiceContainer.getService(IPetDataService) as IPetDataService;
         this.petCorpsService = ServiceContainer.getService(IPetCorpsService) as IPetCorpsService;
         this.summonerDataService = ServiceContainer.getService(ISummonerDataService) as ISummonerDataService;
         this.setTopEff();
         this.petDataService.addEventListener(PetDataServiceEvent.ON_HIGHTES_BATTLE_EFF_UPDATE,this.onUpdateHighest);
         this.petDataService.addEventListener(PetDataServiceEvent.RSPN_VIEW_SINGLE_PM,this.onPetDetailChanged);
         this.petDataService.addEventListener(PetDataServiceEvent.RSPN_VIEW_ALL_PM,this.onPetDetailChanged);
      }
      
      private function onPetDetailChanged(param1:PetDataServiceEvent) : void
      {
         this.setTopEff();
      }
      
      private function onUpdateHighest(param1:PetDataServiceEvent) : void
      {
         this.setTopEff();
      }
      
      private function setTopEff() : void
      {
         ArtNumberManager.setNumber([this.num_0,this.num_1,this.num_2,this.num_3,this.num_4,this.num_5],this.petDataService.getMyPackageEff());
         ArtNumberManager.setNumber([this.max_0,this.max_1,this.max_2,this.max_3,this.max_4,this.max_5,this.max_6],this.petDataService.getHighestBattleEff());
         var _loc1_:MovieClip = this.mcPackageEff;
         TipsManager.getInstance().removeTips(_loc1_);
         TipsManager.getInstance().addComplexTips(_loc1_,"背包战斗力",this.getPackageEffDesc(),0,-40,-80);
         var _loc2_:MovieClip = this.mcHighestEff;
         TipsManager.getInstance().removeTips(_loc2_);
         TipsManager.getInstance().addComplexTips(_loc2_,"拥有的最高的30只亚比的总战力",this.getHighestEffDesc(),0,-40,-80);
      }
      
      private function getHighestEffDesc() : String
      {
         return "最高总战力:" + this.getPetHighestEff() + "\n亚比军团战力:" + this.petCorpsService.getPetCorpsHistoryOfferdHighestBattleEff();
      }
      
      private function getPackageEffDesc() : String
      {
         return "亚比战力:" + this.getPetAddEff() + "\n军团战力:" + this.petCorpsService.getPetCorpsOfferedBattleEff();
      }
      
      private function getPetAddEff() : int
      {
         return this.petDataService.getMyPackageEff() - this.petCorpsService.getPetCorpsOfferedBattleEff() - this.summonerDataService.battlePower;
      }
      
      private function getPetHighestEff() : int
      {
         return this.petDataService.getHighestBattleEff() - this.petCorpsService.getPetCorpsHistoryOfferdHighestBattleEff() - this.summonerDataService.battlePower;
      }
      
      public function dispose() : void
      {
         this.petDataService.removeEventListener(PetDataServiceEvent.ON_HIGHTES_BATTLE_EFF_UPDATE,this.onUpdateHighest);
         this.petDataService.removeEventListener(PetDataServiceEvent.RSPN_VIEW_SINGLE_PM,this.onPetDetailChanged);
         this.petDataService.removeEventListener(PetDataServiceEvent.RSPN_VIEW_ALL_PM,this.onPetDetailChanged);
      }
   }
}

