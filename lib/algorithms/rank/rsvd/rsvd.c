#include "ruby.h"

// For information and references about the module to be stored internally
VALUE RsvdFast = Qnil;

static VALUE method_matrix_approximation(VALUE self, VALUE scores_old, VALUE _v_len, VALUE _p_len, VALUE votes, VALUE _h);

// Initialization method for this module
void Init_rsvd_fast() {
    RsvdFast = rb_define_module("RsvdFast");
    rb_define_method(RsvdFast, "matrix_approximation", method_matrix_approximation, 5);
}

static VALUE method_matrix_approximation(VALUE self, VALUE scores_old, VALUE _v_len, VALUE _p_len, VALUE votes, VALUE _h)
{
    const float v_init = 0.5;
    const float p_init = 0.1;
    const int error_len = 11;
    // in case of a looping non-infinite non-NaN non-converging sequence
    const int max_tries = 100000;
    int i,j,winner,loser,idx,len,num_errs;
    int stop = 0;
    int count = 0;
    long v_len = FIX2LONG(_v_len);
    long p_len = FIX2LONG(_p_len);
    long vp_len = v_len*p_len;
    long votes_len = RARRAY(votes)->len;
    double winner_val,loser_val,e,adj,err;
    double old_num_errs[error_len];
    double old_err[error_len];
    double h = NUM2DBL(_h);
    double *vp = malloc(v_len*sizeof(double));
    double *pp = malloc(p_len*sizeof(double));
    double *dvp = malloc(v_len*sizeof(double));
    double *dpp = malloc(p_len*sizeof(double));
    // scores matrices format: [x,y] = x*height + y
    double *scores_oldp = malloc(vp_len * sizeof(double));
    double *scoresp = malloc(vp_len * sizeof(double));
    VALUE tmp_val;

    if (vp == NULL || pp == NULL || dvp == NULL || dpp == NULL)
        rb_fatal("No memory for vectors");
    if (scoresp == NULL || scores_oldp == NULL)
        rb_fatal("No memory for matrices");

    for (i=0; i<v_len; i++)
        vp[i] = v_init;
    for (i=0; i<p_len; i++)
        pp[i] = p_init;
    for (i=0; i<vp_len; i++)
        scores_oldp[i] = NUM2DBL(rb_ary_entry(scores_old, i));

    while (stop == 0) {
        for (i=0; i<v_len; i++)
            for (j=0; j<p_len; j++)
                scoresp[i*p_len + j] = vp[i] * pp[j];
        for (i=0; i<v_len; i++)
            dvp[i] = 0;
        for (i=0; i<p_len; i++)
            dpp[i] = 0;
        err = 0;
        num_errs = 0;

        for(i=0; i<votes_len; i++) {
            tmp_val = rb_ary_entry(votes, i);
            len = RARRAY(tmp_val)->len;
            idx = i*p_len;
            for(j=0; j<len; j+=2) {
              winner = FIX2INT(rb_ary_entry(tmp_val, j));
              loser = FIX2INT(rb_ary_entry(tmp_val, j+1));
              winner_val = scores_oldp[idx + winner] + scoresp[idx + winner];
              loser_val = scores_oldp[idx + loser] + scoresp[idx + loser];

              e = winner_val-loser_val;
              if (e > 0) num_errs -= 1;
              e = 1 - e;
              err += e*e;
              num_errs++;
              dvp[i] += h*2*e*(pp[winner]-pp[loser]);
              adj = h*2*e*vp[i];
              dpp[loser] -= adj;
              dpp[winner] += adj;
            }
        }
        printf("[%d of %d -- h: %f, num_errs: %d, err:%f]\n", count, max_tries, h, num_errs, err);
        
        // not converging, reset h
        if (isnan(err) != 0 || isinf(err) != 0 || count > max_tries) {
            h /= 2;
            rb_ivar_set(self, 'h', h);
            count = 0;
            for (i=0; i<v_len; i++)
                vp[i] = v_init;
            for (i=0; i<p_len; i++)
                pp[i] = p_init;
        } else {
          for (i=0; i<v_len; i++)
              vp[i] += dvp[i];
          for (i=0; i<p_len; i++)
              pp[i] += dpp[i];
        }

        old_num_errs[error_len - 1] = num_errs;
        old_err[error_len - 1] = err;

        if (++count >= error_len) {
          stop = err_window(old_num_errs, error_len);
          if (stop == 1)
            stop = err_window(old_err, error_len);
        }
        memmove(&old_num_errs[0], &old_num_errs[1], sizeof(double)*(error_len-1));
        memmove(&old_err[0], &old_err[1], sizeof(double)*(error_len-1));
    }

    tmp_val = rb_ary_new2(v_len + p_len);
    for (i=0; i<v_len; i++)
        rb_ary_push(tmp_val, rb_float_new(vp[i]));
    for (; i<v_len+p_len; i++)
        rb_ary_push(tmp_val, rb_float_new(pp[i-v_len]));
    free(vp);
    free(pp);
    free(dvp);
    free(dpp);
    free(scores_oldp);
    free(scoresp);
    return tmp_val;
}

int err_window(double m[], int len)
{
    int i;
    double tmp;
    double res = 0;
    for (i=0; i<len - 1; i++) {
        tmp = m[i] - m[i + 1];
        if (tmp < 0)
            tmp *= -1;
        res += tmp;
    }
    res /= len;
    if (res < 1)
        return 1;
    else
        return 0;
}
