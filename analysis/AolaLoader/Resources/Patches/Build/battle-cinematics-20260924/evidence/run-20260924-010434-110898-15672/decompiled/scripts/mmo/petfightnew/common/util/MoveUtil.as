package mmo.petfightnew.common.util
{
   import com.greensock.TweenMax;
   import com.greensock.data.TweenLiteVars;
   import flash.display.DisplayObject;
   import mmo.interfaces.pet.data.PetAssetsMap;
   import mmo.petfightnew.common.manager.FightTweenMaxManager;
   
   public class MoveUtil
   {
      
      public function MoveUtil()
      {
         super();
      }
      
      public static function move(param1:DisplayObject, param2:Number, param3:Number, param4:Number, param5:Number, param6:Function) : void
      {
         var tweenInit:Function = null;
         var target:DisplayObject = param1;
         var initX:Number = param2;
         var initY:Number = param3;
         var x:Number = param4;
         var y:Number = param5;
         var callBack:Function = param6;
         tweenInit = function():void
         {
            tween(target,initX,initY);
         };
         if(PetAssetsMap.isQuickFight)
         {
            callBack.apply(null,[tweenInit]);
            return;
         }
         tween(target,x,y,function():void
         {
            callBack.apply(null,[tweenInit]);
         });
      }
      
      private static function tween(param1:DisplayObject, param2:Number, param3:Number, param4:Function = null) : void
      {
         var tweenMax:TweenMax = null;
         var target:DisplayObject = param1;
         var x:Number = param2;
         var y:Number = param3;
         var callBack:Function = param4;
         var tweenVars:TweenLiteVars = new TweenLiteVars();
         tweenVars.prop("x",x);
         tweenVars.prop("y",y);
         tweenVars.useFrames(true);
         tweenVars.onComplete(function():void
         {
            FightTweenMaxManager.instance.removeTweenMax(tweenMax);
            if(callBack != null)
            {
               callBack.apply();
            }
         });
         tweenMax = new TweenMax(target,8,tweenVars);
         FightTweenMaxManager.instance.addTweenMax(tweenMax);
      }
   }
}

