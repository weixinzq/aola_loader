package mmo.petfightnew.common.panel
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.text.TextField;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol2505")]
   public class MsgPanel extends Sprite
   {
      
      public var back:MovieClip;
      
      public var btnDown:SimpleButton;
      
      public var btnUp:SimpleButton;
      
      public var txtSys:TextField;
      
      public function MsgPanel()
      {
         super();
      }
      
      public function refresh(param1:String) : void
      {
      }
   }
}

