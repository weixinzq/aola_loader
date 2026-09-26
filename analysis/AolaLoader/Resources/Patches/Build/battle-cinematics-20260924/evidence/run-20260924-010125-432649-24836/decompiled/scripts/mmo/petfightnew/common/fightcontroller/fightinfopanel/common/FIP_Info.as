package mmo.petfightnew.common.fightcontroller.fightinfopanel.common
{
   import flash.events.EventDispatcher;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.FightPanel;
   
   public class FIP_Info extends EventDispatcher
   {
      
      public static const EVENT_CHANGE_TAB:String = "event_change_tab";
      
      public static const EVENT_CHANGE_PET:String = "event_change_pet";
      
      private var _pmSvr:IPMService = ServiceContainer.getService(IPMService);
      
      private var _fightPanel:FightPanel;
      
      private var _leftSecond:int = 0;
      
      private var _selectPetIndex:int;
      
      private var _isSelectMe:Boolean;
      
      public function FIP_Info(param1:FightPanel)
      {
         super();
         this._fightPanel = param1;
      }
      
      public function initSelect() : void
      {
         this._isSelectMe = false;
         this._selectPetIndex = 0;
      }
      
      public function getIsSelectGQPm() : Boolean
      {
         return this._pmSvr.getOperationPM(this.currSelectPbi().raceId).pmData.isGQPM();
      }
      
      public function get leftSecond() : int
      {
         return this._leftSecond;
      }
      
      public function set leftSecond(param1:int) : void
      {
         this._leftSecond = param1;
      }
      
      public function get selectPetIndex() : int
      {
         return this._selectPetIndex;
      }
      
      public function set selectPetIndex(param1:int) : void
      {
         this._selectPetIndex = param1;
      }
      
      public function get isSelectMe() : Boolean
      {
         return this._isSelectMe;
      }
      
      public function setIsSelectMe(param1:Boolean) : void
      {
         this._isSelectMe = param1;
         this._selectPetIndex = 0;
      }
      
      public function get pets() : Array
      {
         return FightData.instance.getInBattleFiledPetBySide(this._isSelectMe).concat();
      }
      
      public function currSelectPbi() : PetBriefInfo
      {
         return this.pets[this._selectPetIndex];
      }
      
      public function get fightPanel() : FightPanel
      {
         return this._fightPanel;
      }
      
      public function dispose() : void
      {
         this._fightPanel = null;
      }
   }
}

