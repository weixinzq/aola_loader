package mmo.petfightnew.common.data
{
   import mmo.common.fetter.Fetter;
   
   public class ActivedFetter
   {
      
      private var _baseFetter:Fetter = null;
      
      private var _level:int = 0;
      
      public function ActivedFetter(param1:Fetter, param2:int)
      {
         super();
         this._baseFetter = param1;
         this._level = param2;
      }
      
      public function get baseFetter() : Fetter
      {
         return this._baseFetter;
      }
      
      public function get level() : int
      {
         return this._level;
      }
   }
}

