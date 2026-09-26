package mmo.petfightnew.common.panel.skillwindword
{
   import flash.display.MovieClip;
   import mmo.petfightnew.common.FightData;
   
   public class SkillWindWordMc extends MovieClip
   {
      
      private var _mc:MovieClip;
      
      public function SkillWindWordMc()
      {
         super();
         var _loc1_:Class = FightData.instance.applicationDomain.getDefinition("mmo.petfightnew.SkillWindWordMv") as Class;
         this._mc = new _loc1_() as MovieClip;
         this._mc.stop();
         this.addChild(this._mc);
      }
      
      public function get mc() : MovieClip
      {
         return this._mc;
      }
   }
}

