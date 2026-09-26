package mmo.petfightnew.common.pet
{
   import flash.display.MovieClip;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.util.BitmapMovieHelper;
   import mmo.play.petfight.common.config.FightResConfig;
   
   public class VectorgraphPetMovieStrategy extends PetMovieStrategyBase
   {
      
      private var _sourcePetMovie:MovieClip;
      
      public function VectorgraphPetMovieStrategy(param1:int, param2:int)
      {
         super(param1,param2);
      }
      
      override protected function getTargetPetClsName() : String
      {
         return FightResConfig.getSinglePetMovieClsName(this._raceId,this._face);
      }
      
      override protected function onResPrepared() : void
      {
         this.initSourcePetMovie();
         super.onResPrepared();
      }
      
      private function initSourcePetMovie() : void
      {
         var _loc1_:String = this.getTargetPetClsName();
         if(!this.haveDefinitionInFightDomain(_loc1_))
         {
            this._useDefault = true;
            _loc1_ = FightResConfig.getSinglePetMovieClsName(FightResConfig.DEFAULT_PET_ID,this._face);
         }
         this._sourcePetMovie = this.getPetMovie(_loc1_);
      }
      
      override public function getActionMovie(param1:int) : MovieClip
      {
         var _loc2_:MovieClip = this.getMovieCache(param1);
         if(_loc2_ == null)
         {
            _loc2_ = this.getNewActionMovie(param1);
         }
         if(_loc2_ == null)
         {
            _loc2_ = this.getNewActionMovie(param1);
         }
         return _loc2_;
      }
      
      private function getNewActionMovie(param1:int) : MovieClip
      {
         var _loc2_:MovieClip = null;
         var _loc3_:Number = NaN;
         var _loc4_:MovieClip = null;
         if(this.gotoAvailableActFrame(param1))
         {
            _loc2_ = this._sourcePetMovie.getChildByName("mc") as MovieClip;
            if(_loc2_ == null)
            {
               if(this._sourcePetMovie.numChildren <= 0)
               {
                  return null;
               }
               _loc2_ = this._sourcePetMovie.getChildAt(0) as MovieClip;
            }
            _loc3_ = FightData.instance.getPetVisionScale();
            _loc2_.scaleX *= _loc3_;
            _loc2_.scaleY *= _loc3_;
            _loc2_.x = this._sourcePetMovie.x + _loc2_.x * _loc3_;
            _loc2_.y = this._sourcePetMovie.y + _loc2_.y * _loc3_;
            _loc4_ = BitmapMovieHelper.toSyncBitmapMovie(_loc2_);
            this.cacheMovie(param1,_loc4_);
            return _loc4_;
         }
         return null;
      }
      
      private function gotoAvailableActFrame(param1:int) : Boolean
      {
         var _loc5_:int = 0;
         var _loc2_:int = PetActionFrame.getActionIndex(param1);
         if(_loc2_ == -1)
         {
            return false;
         }
         var _loc3_:Array = PetActionFrame.ACTION_PRIORITY[_loc2_];
         var _loc4_:int = 0;
         while(_loc4_ < _loc3_.length)
         {
            _loc5_ = int(_loc3_[_loc4_]);
            this._sourcePetMovie.gotoAndStop(_loc5_);
            if(this._sourcePetMovie.numChildren > 0)
            {
               return true;
            }
            _loc4_++;
         }
         return false;
      }
   }
}

