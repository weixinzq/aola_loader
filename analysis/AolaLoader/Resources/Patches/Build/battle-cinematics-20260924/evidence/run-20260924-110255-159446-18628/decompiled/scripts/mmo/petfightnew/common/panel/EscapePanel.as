package mmo.petfightnew.common.panel
{
   import flash.display.MovieClip;
   import mmo.common.utils.tips.TipsManager;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol3814")]
   public class EscapePanel extends MovieClip
   {
      
      public function EscapePanel()
      {
         addFrameScript(0,this.frame1);
         super();
      }
      
      override public function gotoAndStop(param1:Object, param2:String = null) : void
      {
         super.gotoAndStop(param1,param2);
         this.updateTips();
      }
      
      private function updateTips() : void
      {
         if(2 == this.currentFrame)
         {
            TipsManager.getInstance().replaceTips(this,"该场战斗亚比不能逃跑！",0,-50,-20);
         }
         else
         {
            TipsManager.getInstance().replaceTips(this,"可让所有亚比全部逃离战斗！",0,-50,-20);
         }
      }
      
      internal function frame1() : *
      {
         stop();
      }
   }
}

