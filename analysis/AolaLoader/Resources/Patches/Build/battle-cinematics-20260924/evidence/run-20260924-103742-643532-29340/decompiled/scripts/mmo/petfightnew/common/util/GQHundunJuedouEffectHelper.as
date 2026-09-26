package mmo.petfightnew.common.util
{
   public class GQHundunJuedouEffectHelper
   {
      
      private static const BitmapScreenKey:String = "hundunJuedouScreenEffect";
      
      private static const URL:String = "gqpet/hundunjuedou/effect/hundunjuedoueffect";
      
      private static const CLS:String = "mmo.gqpet.hundunjuedou.effect.HunDunJueDouAppearEffect";
      
      public function GQHundunJuedouEffectHelper()
      {
         super();
      }
      
      public static function addScreenBitmap() : void
      {
         playAnimation(URL,CLS);
      }
      
      public static function removeScreenBitmap() : void
      {
      }
      
      private static function playAnimation(param1:String, param2:String, param3:Boolean = false, param4:Function = null) : void
      {
         /*
          * Decompilation error
          * Code may be obfuscated
          * Tip: You can try enabling "Deobfuscate code" option in Settings
          * Error type: ClassCastException (com.jpexs.decompiler.graph.model.CommaExpressionItem cannot be cast to com.jpexs.decompiler.flash.abc.avm2.model.NewFunctionAVM2Item)
          */
         throw new flash.errors.IllegalOperationError("Not decompiled due to error");
      }
   }
}

