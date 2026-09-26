package mmo.petfightnew.common.manager
{
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.option.IGameOptionService;
   import mmo.loader.LoaderContainer;
   
   public class FightFrameRateManager
   {
      
      private static var _instance:FightFrameRateManager = null;
      
      private var _gameOptionSvr:IGameOptionService = ServiceContainer.getService(IGameOptionService);
      
      private var _defaultFrameRate:int = 25;
      
      public function FightFrameRateManager()
      {
         super();
      }
      
      public static function get instance() : FightFrameRateManager
      {
         return _instance = _instance || new FightFrameRateManager();
      }
      
      public function correctFrameRate() : void
      {
         this.changeFrameRate(this._defaultFrameRate);
      }
      
      public function changeFrameRate(param1:int) : void
      {
         if(param1 > 0)
         {
            LoaderContainer.instance.stage.frameRate = param1;
            this._defaultFrameRate = param1;
         }
      }
      
      public function dispose() : void
      {
         if(this._gameOptionSvr.isHighFrameRate)
         {
            this.changeFrameRate(50);
         }
         else
         {
            this.changeFrameRate(25);
         }
         _instance = null;
      }
      
      public function get defaultFrameRate() : int
      {
         return this._defaultFrameRate;
      }
   }
}

