package mmo.petfightnew.common.fightcontroller.fightinfopanel
{
   import mmo.interfaces.IDispose;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.petfightnew.common.FightPanel;
   import mmo.petfightnew.common.event.FightEventDispatcher;
   import mmo.petfightnew.common.fightcontroller.fightinfopanel.common.FIP_Info;
   import mmo.petfightnew.common.fightcontroller.fightinfopanel.panel.FIP_MainPl;
   
   public class FIP_Controller implements IDispose
   {
      
      private static var _instance:FIP_Controller;
      
      private var _info:FIP_Info = null;
      
      private var _mainPl:FIP_MainPl;
      
      public function FIP_Controller()
      {
         super();
      }
      
      public static function get instance() : FIP_Controller
      {
         if(_instance == null)
         {
            _instance = new FIP_Controller();
         }
         return _instance;
      }
      
      public function init(param1:FightPanel) : void
      {
         this._info = new FIP_Info(param1);
         this.addEventListener();
      }
      
      public function showMainPl() : void
      {
         if(this._mainPl != null)
         {
            this._mainPl.dispose();
         }
         this._mainPl = new FIP_MainPl(this._info);
         this._mainPl.showPanel();
      }
      
      private function addEventListener() : void
      {
         FightEventDispatcher.instance.addEventListener(PetFightEvent.ON_COUNTDOWN,this.onCountDown);
      }
      
      private function onCountDown(param1:PetFightEvent) : void
      {
         this._info.leftSecond = param1.params.leftSecond;
         if(Boolean(this._mainPl) && this._mainPl.isShow)
         {
            this._mainPl.refreshSecond();
         }
      }
      
      public function dispose() : void
      {
         FightEventDispatcher.instance.removeEventListener(PetFightEvent.ON_COUNTDOWN,this.onCountDown);
         this._info && this._info.dispose();
         this._info = null;
         this._mainPl && this._mainPl.dispose();
         this._mainPl = null;
         _instance = null;
      }
   }
}

