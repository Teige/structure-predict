structure-predict
=================

Scripting my structure prediction workflow


1.  Acquire ‘target seq’ = campy seq
2.  jackhmmer -N <5> -A <alnfile.stockholm> --noali --notextw --incE 0.001 --max --cpu <12>  <target seq> <nr fasta database> #make note of database version!
3.  parse alnfile output to raw seqs & FASTA format using clean_hmmer.lines script, keep both (raw & FASTA) formats.
4.  psicov <rawalnfile> >target.con #-d <nnn> to set target precision matrix sparsity (find out appropriate target for TM proteins!)
5.  tcsh runpsipred <target seq> #set db in script, should db be filtered in the case of TM proteins?
6.  perl run_memsat-svm.pl -d <nr> <target seq> #can jackhmmer replace psiblast in memsat?
7.  generate target.zcoord
8.  generate ssfile <target.ess> in appropriate format (combine psipred/memsat script?)
9.  create target.nfpar file:
  ALNFILE <target.aln> (raw format)
  INITEMP 0.6
  MAXSTEPS 20000000 (2*10^7)
  POOLSIZE 9
  TRATIO 0.6
  MAXFRAGS 5
  MAXFRAGS2 25
  CONFILE <target.con>
  ZFILE <target.zcoord> #if reliable zcoords generated from memsat
10. Parallelize film3 with GNU parallel
11. Determine minimum energy model with film3_minimum_energy.lines
12. Edit super_models.csh with min energy model and whole set directories
13. tcsh supermodels.csh #uses ProFitV3.1 to generate ensemble.pdb
14. contactrecomb ensemble.pdb <target.con> <target.ess> <final.pdb>
15. model quality assessment with film3mqap
16. model refinement! MODELLER….
