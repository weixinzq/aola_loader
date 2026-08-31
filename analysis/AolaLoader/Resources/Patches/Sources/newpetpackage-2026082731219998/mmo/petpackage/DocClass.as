package mmo.petpackage
{
   import flash.display.MovieClip;
   import mmo.petpackage.data.PetDetailDataMap;
   import mmo.petpackage.service.PetPackageService;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol401")]
   public class DocClass extends MovieClip
   {
      
      public function DocClass()
      {
         super();
      }
      
      private function compile() : void
      {
         var _loc1_:PetPackageService = null;
         var _loc2_:PetDetailDataMap = null;
      }
   }
}

