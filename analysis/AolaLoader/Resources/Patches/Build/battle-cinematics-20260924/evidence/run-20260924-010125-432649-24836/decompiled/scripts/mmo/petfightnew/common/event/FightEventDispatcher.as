package mmo.petfightnew.common.event
{
   import flash.events.EventDispatcher;
   
   public class FightEventDispatcher extends EventDispatcher
   {
      
      private static var _instance:FightEventDispatcher;
      
      public function FightEventDispatcher()
      {
         super();
      }
      
      public static function get instance() : FightEventDispatcher
      {
         if(_instance == null)
         {
            _instance = new FightEventDispatcher();
         }
         return _instance;
      }
      
      public function dispose() : void
      {
         _instance = null;
      }
   }
}

