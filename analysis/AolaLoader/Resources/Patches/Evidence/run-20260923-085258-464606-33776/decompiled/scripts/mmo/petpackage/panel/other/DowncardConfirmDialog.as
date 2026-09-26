package mmo.petpackage.panel.other
{
   import flash.display.SimpleButton;
   import flash.text.TextField;
   import mmo.common.dialog.DialogBase;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol455")]
   public class DowncardConfirmDialog extends DialogBase
   {
      
      public var btnCancel:SimpleButton;
      
      public var btnOk:SimpleButton;
      
      public var info:TextField;
      
      public function DowncardConfirmDialog(param1:String)
      {
         super(param1);
      }
   }
}

