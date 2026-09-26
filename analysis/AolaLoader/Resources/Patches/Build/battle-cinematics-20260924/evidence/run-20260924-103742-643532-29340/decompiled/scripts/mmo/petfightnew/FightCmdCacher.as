package mmo.petfightnew
{
   import flash.events.Event;
   
   public class FightCmdCacher
   {
      
      private var cmdArr:Array = [];
      
      public function FightCmdCacher()
      {
         super();
      }
      
      public function cacheCmd(param1:int, param2:Event, param3:Boolean = false) : void
      {
         var _loc4_:Array = null;
         if(param3)
         {
            _loc4_ = new Array();
            this.cmdArr.push(_loc4_);
         }
         else
         {
            _loc4_ = this.cmdArr[this.cmdArr.length - 1];
         }
         if(_loc4_ == null)
         {
            return;
         }
         var _loc5_:Object = {
            "cmd":param1,
            "evt":param2
         };
         _loc4_.push(_loc5_);
      }
      
      public function getOneCache() : Array
      {
         return this.cmdArr.shift();
      }
   }
}

