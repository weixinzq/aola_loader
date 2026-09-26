package mmo.petfightnew.common.panel
{
   import flash.display.MovieClip;
   import mmo.common.utils.tips.TipsManager;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol3582")]
   public class CatchIcon extends MovieClip
   {
      
      public function CatchIcon()
      {
         super();
      }
      
      override public function gotoAndStop(param1:Object, param2:String = null) : void
      {
         super.gotoAndStop(param1,param2);
         this.changeTips();
      }
      
      private function changeTips() : void
      {
         if(this.currentFrame == 1)
         {
            TipsManager.getInstance().replaceTips(this,"可使用背包内“亚比捕捉球”捕捉野外亚比！",0,-80,-20);
         }
         else if(this.currentFrame == 2)
         {
            TipsManager.getInstance().replaceTips(this,"该场战斗不能捕捉亚比！",0,-50,-20);
         }
         else
         {
            TipsManager.getInstance().removeTips(this);
         }
      }
   }
}

