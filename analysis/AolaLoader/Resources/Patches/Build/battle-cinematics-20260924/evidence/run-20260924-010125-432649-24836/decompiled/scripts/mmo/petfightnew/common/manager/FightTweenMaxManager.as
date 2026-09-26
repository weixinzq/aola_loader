package mmo.petfightnew.common.manager
{
   import com.greensock.TweenMax;
   
   public class FightTweenMaxManager
   {
      
      private static var _instance:FightTweenMaxManager = null;
      
      private var _tweenMaxList:Vector.<TweenMax> = new Vector.<TweenMax>();
      
      public function FightTweenMaxManager()
      {
         super();
      }
      
      public static function get instance() : FightTweenMaxManager
      {
         return _instance = _instance || new FightTweenMaxManager();
      }
      
      public function addTweenMax(param1:TweenMax) : void
      {
         if(this._tweenMaxList.indexOf(param1) == -1)
         {
            this._tweenMaxList.push(param1);
         }
      }
      
      public function removeTweenMax(param1:TweenMax) : void
      {
         var _loc2_:int = int(this._tweenMaxList.indexOf(param1));
         if(_loc2_ >= 0)
         {
            this._tweenMaxList.splice(_loc2_,1);
         }
      }
      
      public function pause() : void
      {
         var _loc1_:TweenMax = null;
         for each(_loc1_ in this._tweenMaxList)
         {
            _loc1_.pause();
         }
      }
      
      public function play() : void
      {
         var _loc1_:TweenMax = null;
         for each(_loc1_ in this._tweenMaxList)
         {
            _loc1_.play();
         }
      }
      
      public function dispose() : void
      {
         var _loc1_:TweenMax = null;
         for each(_loc1_ in this._tweenMaxList)
         {
            _loc1_.pause();
            _loc1_.kill();
         }
         this._tweenMaxList = new Vector.<TweenMax>();
         _instance = null;
      }
   }
}

